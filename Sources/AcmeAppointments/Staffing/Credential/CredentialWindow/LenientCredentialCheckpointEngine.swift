import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the lenient credential checkpoint calculation.
    protocol LenientCredentialCheckpointAdjuster {
        func describe() -> String
        func adjust(_ item: LenientCredentialCheckpoint, value: Double) -> Double
    }

    final class LenientCredentialCheckpointRatioOffsetAdjuster: LenientCredentialCheckpointAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: LenientCredentialCheckpoint, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    final class FlaggedLenientCredentialCheckpointAdjuster: LenientCredentialCheckpointAdjuster {
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

        func adjust(_ item: LenientCredentialCheckpoint, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingLenientCredentialCheckpointAdjuster: LenientCredentialCheckpointAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientCredentialCheckpoint, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumLenientCredentialCheckpointAdjuster: LenientCredentialCheckpointAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientCredentialCheckpoint, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the lenient credential checkpoint steps in order and keeps a trace of each.
    final class LenientCredentialCheckpointEngine {
        var steps: [any LenientCredentialCheckpointAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientCredentialCheckpointAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LenientCredentialCheckpoint) -> Double {
            var current = item.measuredValue()
            trace = []
            for step in steps {
                let next = step.adjust(item, value: current)
                trace.append("\(step.describe()): \((current * 100).rounded() / 100) -> \((next * 100).rounded() / 100)")
                current = next
            }
            return Kit.Numbers.clampFloat(current, low: floor, high: ceiling)
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [LenientCredentialCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLenientCredentialCheckpointEngine(_ flags: Kit.Flags.Registry) -> LenientCredentialCheckpointEngine {
        return LenientCredentialCheckpointEngine(
            steps: [
                LenientCredentialCheckpointRatioOffsetAdjuster(weight: 0.9),
                FlaggedLenientCredentialCheckpointAdjuster(
                    flags: flags,
                    flag: "lenient-credential-checkpoint-tiered",
                    percent: 6.1
                ),
                RoundingLenientCredentialCheckpointAdjuster(step: 5.0),
                MinimumLenientCredentialCheckpointAdjuster(minimum: 39.3),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 28477.6
        )
    }
}
