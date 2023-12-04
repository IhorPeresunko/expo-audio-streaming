export interface PlayerConfiguration {
  sampleRate?: number;
  channels?: number;
}

export interface PlayerBufferPlayedEvent {
  buffersInQueue: number;
}

export interface RecorderConfiguration {
  outputSampleRate?: number;
  channels?: number;
}

export interface RecorderNewBufferEvent {
  buffer: string;
}
