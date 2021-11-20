import { Request, Response, NextFunction } from "express";

import { logger } from "../../config/logger";
import * as streamService from "../../services/stream/stream";
import * as websocketService from "../../services/ws/ws";
import { showReadableStreamMode } from "../../utils/log";

export async function push(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  websocketService.clientStore.on(
    "update_client_count",
    streamService.updateListenerPeakCount,
  );
  streamService.inoutStream.once("pause", () => {
    websocketService.clientStore.removeListener(
      "update_client_count",
      streamService.updateListenerPeakCount,
    );
  });

  try {
    await streamService.startBroadcast({
      listenersNow: websocketService.clientStore.clientCount,
    });

    logger.debug(`${__filename} Starting push stream from client to server...`);
    // When broadcast-client connects, switch the stream back into the 'flowing' mode, otherwise later we won't be able to push data to listener-clients requests
    streamService.inoutStream.resume();

    req.on("data", onReqData);
    req.on("error", onErr);
    req.on("end", onEnd);
    req.on("close", onClose);
  } catch (err) {
    next(err);
  }
}

async function onReqData(chunk: Buffer) {
  //showReadableStreamMode(
  //  streamService.inoutStream,
  //  "broadcaster's push stream",
  //);

  // Push incoming request data into Readable stream in order to be able to consume it later on listener-client request (it doesn't accumulates in memory, it is just lost)
  streamService.inoutStream.push(chunk);
}

async function onClose() {
  logger.debug(
    `${__filename} [close] Broadcasting client has closed the request (push audio stream).`,
  );
  await streamService.endBroadcast();

  // We shouldn't use 'close' and/or 'end' methods on the read/write streams of our duplex stream, otherwise the broadcast-client won't be able to reconnect and start pushing again until the server restart. 'pause' is the most appropriate alternative to these methods
  streamService.inoutStream.pause();
  showReadableStreamMode(
    streamService.inoutStream,
    "broadcaster's push stream",
  );
}

function onEnd() {
  logger.debug(`${__filename} [end] No more data in request stream.`);
  showReadableStreamMode(
    streamService.inoutStream,
    "broadcaster's push stream",
  );
}

async function onErr(err: Error) {
  logger.error(`${__filename} [error] ${err}`);
  showReadableStreamMode(
    streamService.inoutStream,
    "broadcaster's push stream",
  );
  await streamService.endBroadcast();
}
