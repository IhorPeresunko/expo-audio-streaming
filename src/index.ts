import { EventEmitter, Subscription } from "expo-modules-core";
import ExpoAudioStreamingModule from "./ExpoAudioStreamingModule";
import * as Types from "./ExpoAudioStreamingModule.types";

const emitter = new EventEmitter(ExpoAudioStreamingModule);

function addListener(
  eventName: string,
  listener: (event) => void
): Subscription {
  return emitter.addListener(eventName, listener);
}

export const Player = {
  addOnBufferPlayedListener(
    listener: (event: Types.PlayerBufferPlayedEvent) => void
  ): Subscription {
    return addListener("onBufferPlayedPlayer", listener);
  },

  addOnBufferEmptyListener(listener: (event) => void): Subscription {
    return addListener("onBufferEmptyPlayer", listener);
  },

  play(): void {
    ExpoAudioStreamingModule.playPlayer();
  },

  pause(): void {
    ExpoAudioStreamingModule.pausePlayer();
  },

  addToQueue(base64: string) {
    ExpoAudioStreamingModule.addToQueuePlayer(base64);
  },
};

export const Recorder = {
  addOnNewBufferListener(
    listener: (event: Types.RecorderNewBufferEvent) => void
  ): Subscription {
    return addListener("onNewBufferRecorder", listener);
  },

  start(): void {
    ExpoAudioStreamingModule.startRecorder();
  },

  stop(): void {
    ExpoAudioStreamingModule.stopRecorder();
  },
};

export const AudioSession = {
  init: (config: Types.AudioSessionConfiguration = {}) => {
    const c: Types.AudioSessionConfiguration = {
      playerSampleRate: 44100,
      playerChannels: 1,
      recorderSampleRate: 44100,
      ...config,
    };

    ExpoAudioStreamingModule.init(
      c.recorderSampleRate,
      c.playerSampleRate,
      c.playerChannels
    );
  },
  destroy: ExpoAudioStreamingModule.destroy,
};

export * as Types from "./ExpoAudioStreamingModule.types";
