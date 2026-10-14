import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the default worklist checkpoint calculation.
    protocol DefaultWorklistCheckpointStep {
        func describe() -> String
        func adjust(_ item: DefaultWorklistCheckpoint, value: Double) -> Double
    }

    final class MinimumDefaultWorklistCheckpointAdjuster: DefaultWorklistCheckpointStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultWorklistCheckpoint, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedDefaultWorklistCheckpointAdjuster: DefaultWorklistCheckpointStep {
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

        func adjust(_ item: DefaultWorklistCheckpoint, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentDefaultWorklistCheckpointAdjuster: DefaultWorklistCheckpointStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultWorklistCheckpoint, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class DefaultWorklistCheckpointDosageMgOffsetAdjuster: DefaultWorklistCheckpointStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: DefaultWorklistCheckpoint, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    final class CapDefaultWorklistCheckpointAdjuster: DefaultWorklistCheckpointStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultWorklistCheckpoint, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the default worklist checkpoint steps in order and keeps a trace of each.
    final class DefaultWorklistCheckpointEngineExtra {
        var steps: [any DefaultWorklistCheckpointStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultWorklistCheckpointStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DefaultWorklistCheckpoint) -> Double {
            var current = item.effectiveVolume()
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

        func evaluateAll(_ items: [DefaultWorklistCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDefaultWorklistCheckpointEngine(_ flags: Kit.Flags.Registry) -> DefaultWorklistCheckpointEngineExtra {
        return DefaultWorklistCheckpointEngineExtra(
            steps: [
                MinimumDefaultWorklistCheckpointAdjuster(minimum: 46.2),
                FlaggedDefaultWorklistCheckpointAdjuster(
                    flags: flags,
                    flag: "default-worklist-checkpoint-tiered",
                    percent: 3.4
                ),
                PercentDefaultWorklistCheckpointAdjuster(percent: -16.2),
                DefaultWorklistCheckpointDosageMgOffsetAdjuster(weight: 0.51),
                CapDefaultWorklistCheckpointAdjuster(cap: 23118.0),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 45106.3
        )
    }
}
