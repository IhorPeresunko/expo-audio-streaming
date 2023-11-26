import { StyleSheet, Text, TouchableOpacity, View } from "react-native";
import Base64 from "base-64";

import { usePlayer } from "./usePlayer";
import { audio } from "./mock-stream";
import { useRecorder } from "./useRecorder";

export default function App() {
  const { addToBuffer, play, pause, playing } = usePlayer();
  const { start, stop, recording, buffer } = useRecorder({
    onNewBuffer: (event) => event,
  });

  const startStreamingMockData = () => {
    for (let i = 0; i < audio.length; i++) {
      setTimeout(() => {
        addToBuffer(audio[i]);
      }, i * 100);
    }
  };

  const startStreamingRecordingData = () => {
    for (let i = 0; i < buffer.length; i++) {
      addToBuffer(buffer[i]);
    }
  };

  return (
    <View style={styles.container}>
      <Text>Status: {playing ? "Playing" : "Not Playing"}</Text>
      {playing ? (
        <TouchableOpacity onPress={pause} style={styles.button}>
          <Text>Stop Playing</Text>
        </TouchableOpacity>
      ) : (
        <TouchableOpacity onPress={play} style={styles.button}>
          <Text>Start Playing</Text>
        </TouchableOpacity>
      )}

      <TouchableOpacity onPress={startStreamingMockData} style={styles.button}>
        <Text>Stream mock buffer to player</Text>
      </TouchableOpacity>

      <Text style={styles.p}>--------</Text>

      <Text>Status: {recording ? "Recording" : "Not Recording"}</Text>
      {recording ? (
        <TouchableOpacity onPress={stop} style={styles.button}>
          <Text>Stop Recording</Text>
        </TouchableOpacity>
      ) : (
        <TouchableOpacity onPress={start} style={styles.button}>
          <Text>Start Recording</Text>
        </TouchableOpacity>
      )}
      <TouchableOpacity
        onPress={startStreamingRecordingData}
        style={styles.button}
      >
        <Text>Stream recording buffer to player</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#fff",
    alignItems: "center",
    justifyContent: "center",
  },
  button: {
    padding: 10,
    backgroundColor: "#EBEBEB",
    borderRadius: 5,
    marginTop: 10,
  },
  p: {
    paddingVertical: 40,
  },
});
