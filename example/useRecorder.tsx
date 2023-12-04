import { Recorder, Types } from "expo-audio-streaming";
import { useState, useCallback, useEffect } from "react";

export const useRecorder = ({
  onNewBuffer,
  outputSampleRate,
}: {
  /**
   * Callback when a new buffer is recorded
   * @param event.buffer The base64 encoded buffer
   */
  onNewBuffer: (event: Types.RecorderNewBufferEvent) => void;
  /**
   * The sample rate of the output buffer
   * @default 16000
   */
  outputSampleRate?: number;
}) => {
  const [recording, setRecording] = useState(false);
  const [buffer, setBuffer] = useState<string[]>([]);

  const start = useCallback(async () => {
    await Recorder.start();
    setRecording(true);
  }, [setRecording]);

  const stop = useCallback(() => {
    Recorder.stop();
    setRecording(false);
  }, [setRecording]);

  const _onNewBuffer = useCallback(
    (event: Types.RecorderNewBufferEvent) => {
      setBuffer((prev) => [...prev, event.buffer]);
      onNewBuffer(event);
    },
    [onNewBuffer, setBuffer]
  );

  useEffect(() => {
    const onNewBufferListener = Recorder.addOnNewBufferListener(_onNewBuffer);

    return () => {
      onNewBufferListener.remove();
    };
  }, [_onNewBuffer]);

  useEffect(() => {
    Recorder.init({ outputSampleRate });
  }, []);

  return {
    start,
    stop,
    buffer,

    recording,
  };
};
