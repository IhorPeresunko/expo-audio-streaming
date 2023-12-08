export interface AudioSessionConfiguration {
  playerSampleRate?: number;
  playerChannels?: number;
  recorderSampleRate?: number;
  recorderBufferSize?: number;
  recorderChannels?: number;
}

export interface PlayerBufferPlayedEvent {
  buffersInQueue: number;
}

export interface RecorderNewBufferEvent {
  buffer: string;
}
