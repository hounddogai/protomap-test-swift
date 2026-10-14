import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the weighted isolation entry calculation.
    protocol WeightedIsolationEntryStep {
        func describe() -> String
        func adjust(_ item: WeightedIsolationEntry, value: Double) -> Double
    }

    final class RoundingWeightedIsolationEntryAdjuster: WeightedIsolationEntryStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedIsolationEntry, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumWeightedIsolationEntryAdjuster: WeightedIsolationEntryStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedIsolationEntry, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class WeightedIsolationEntryCeilingOffsetAdjuster: WeightedIsolationEntryStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: WeightedIsolationEntry, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    final class FlaggedWeightedIsolationEntryAdjuster: WeightedIsolationEntryStep {
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

        func adjust(_ item: WeightedIsolationEntry, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the weighted isolation entry steps in order and keeps a trace of each.
    final class WeightedIsolationEntryEngine {
        var steps: [any WeightedIsolationEntryStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedIsolationEntryStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: WeightedIsolationEntry) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any WeightedIsolationEntryStep = steps[index]
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

        func evaluateAll(_ items: [WeightedIsolationEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultWeightedIsolationEntryEngine(_ flags: Kit.Flags.Registry) -> WeightedIsolationEntryEngine {
        return WeightedIsolationEntryEngine(
            steps: [
                RoundingWeightedIsolationEntryAdjuster(step: 1.0),
                MinimumWeightedIsolationEntryAdjuster(minimum: 49.8),
                WeightedIsolationEntryCeilingOffsetAdjuster(weight: 0.83),
                FlaggedWeightedIsolationEntryAdjuster(
                    flags: flags,
                    flag: "weighted-isolation-entry-batched",
                    percent: 5.2
                ),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 73439.3
        )
    }
}
