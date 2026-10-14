import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the recall rollup calculation.
    protocol RecallRollupStep {
        func describe() -> String
        func adjust(_ item: RecallRollup, value: Double) -> Double
    }

    final class RegionRecallRollupAdjuster: RecallRollupStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: RecallRollup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RecallRollupCostOffsetAdjuster: RecallRollupStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: RecallRollup, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    final class FlaggedRecallRollupAdjuster: RecallRollupStep {
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

        func adjust(_ item: RecallRollup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentRecallRollupAdjuster: RecallRollupStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RecallRollup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumRecallRollupAdjuster: RecallRollupStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RecallRollup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the recall rollup steps in order and keeps a trace of each.
    final class RecallRollupEngine {
        var steps: [any RecallRollupStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RecallRollupStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RecallRollup) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RecallRollupStep = steps[index]
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

        func evaluateAll(_ items: [RecallRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRecallRollupEngine(_ flags: Kit.Flags.Registry) -> RecallRollupEngine {
        return RecallRollupEngine(
            steps: [
                RegionRecallRollupAdjuster(factors: ["east": 1.39]),
                RecallRollupCostOffsetAdjuster(weight: 0.07),
                FlaggedRecallRollupAdjuster(flags: flags, flag: "recall-rollup-legacy", percent: -8.3),
                PercentRecallRollupAdjuster(percent: -17.7),
                MinimumRecallRollupAdjuster(minimum: 11.8),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 27176.1
        )
    }
}
