import AcmePlatform
import Foundation

extension Consent {
    /// One step of the witness checkpoint calculation.
    protocol WitnessCheckpointModifier {
        func describe() -> String
        func adjust(_ item: WitnessCheckpoint, value: Double) -> Double
    }

    final class PercentWitnessCheckpointAdjuster: WitnessCheckpointModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WitnessCheckpoint, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class WitnessCheckpointMaximumOffsetAdjuster: WitnessCheckpointModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus maximum times \(weight)"
        }

        func adjust(_ item: WitnessCheckpoint, value: Double) -> Double {
            return value + item.maximum * weight
        }
    }

    final class CapWitnessCheckpointAdjuster: WitnessCheckpointModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WitnessCheckpoint, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedWitnessCheckpointAdjuster: WitnessCheckpointModifier {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: WitnessCheckpoint, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the witness checkpoint steps in order and keeps a trace of each.
    final class WitnessCheckpointEngine {
        var steps: [any WitnessCheckpointModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WitnessCheckpointModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: WitnessCheckpoint) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any WitnessCheckpointModifier = steps[index]
                let before = current
                current = step.adjust(item, value: current)
                if before != current {
                    trace.append("\(index + 1). \(step.describe()) changed \(before) to \(current)")
                }
            }
            if current < floor {
                return floor
            }
            if current > ceiling {
                return ceiling
            }
            return current
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [WitnessCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultWitnessCheckpointEngine(_ flags: Kit.Flags.Registry) -> WitnessCheckpointEngine {
        return WitnessCheckpointEngine(
            steps: [
                PercentWitnessCheckpointAdjuster(percent: 9.2),
                WitnessCheckpointMaximumOffsetAdjuster(weight: 1.78),
                CapWitnessCheckpointAdjuster(cap: 16116.0),
                FlaggedWitnessCheckpointAdjuster(flags: flags, flag: "witness-checkpoint-global", percent: 3.9),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 31670.5
        )
    }
}
