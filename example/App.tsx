import { StyleSheet, Text, TouchableOpacity, View } from "react-native";

import { usePlayer } from "./usePlayer";
import { audio } from "./mock-stream";

export default function App() {
  const { addToBuffer, play, pause, playing } = usePlayer();

  const startStreaming = () => {
    for (let i = 0; i < audio.length; i++) {
      setTimeout(() => {
        addToBuffer(audio[i]);
      }, i * 100);
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

      <TouchableOpacity onPress={startStreaming} style={styles.button}>
        <Text>Start Streaming</Text>
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
});
