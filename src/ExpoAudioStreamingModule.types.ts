export interface PlayerConfiguration {
  sampleRate?: number;
  channels?: number;
}

export interface PlayerBufferPlayedEvent {
  buffersInQueue: number;
}

export interface RecorderNewBufferEvent {
  buffer: string;
}
