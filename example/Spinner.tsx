import React, { useEffect, useRef } from "react";
import { StyleSheet, View, ColorValue, Animated, Easing } from "react-native";

interface Props {
  color: ColorValue;
  durationMs?: number;
  testID?: string;
}

const startRotationAnimation = (
  durationMs: number,
  rotationDegree: Animated.Value
): void => {
  Animated.loop(
    Animated.timing(rotationDegree, {
      toValue: 360,
      duration: durationMs,
      easing: Easing.linear,
      useNativeDriver: true,
    })
  ).start();
};

const durationMs = 1000;
const Spinner = () => {
  const rotationDegree = useRef(new Animated.Value(0)).current;
  const color = "blue";

  useEffect(() => {
    startRotationAnimation(durationMs, rotationDegree);
  }, [durationMs, rotationDegree]);

  return (
    <View style={styles.container} accessibilityRole="progressbar">
      <View style={[styles.background, { borderColor: color }]} />

      <Animated.View
        style={[
          styles.progress,
          { borderTopColor: color },
          {
            transform: [
              {
                rotateZ: rotationDegree.interpolate({
                  inputRange: [0, 360],
                  outputRange: ["0deg", "360deg"],
                }),
              },
            ],
          },
        ]}
      />
    </View>
  );
};

const height = 24;

const styles = StyleSheet.create({
  container: {
    width: height,
    height: height,
    justifyContent: "center",
    alignItems: "center",
  },
  background: {
    width: "100%",
    height: "100%",
    borderRadius: height / 2,
    borderWidth: 4,
    opacity: 0.25,
  },
  progress: {
    width: "100%",
    height: "100%",
    borderRadius: height / 2,
    borderLeftColor: "transparent",
    borderRightColor: "transparent",
    borderBottomColor: "transparent",
    borderWidth: 4,
    position: "absolute",
  },
});

export default Spinner;
