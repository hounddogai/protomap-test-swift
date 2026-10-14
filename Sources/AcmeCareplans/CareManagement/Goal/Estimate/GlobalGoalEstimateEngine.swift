import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the global goal estimate calculation.
    protocol GlobalGoalEstimateAdjuster {
        func describe() -> String
        func adjust(_ item: GlobalGoalEstimate, value: Double) -> Double
    }

    final class RoundingGlobalGoalEstimateAdjuster: GlobalGoalEstimateAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalGoalEstimate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedGlobalGoalEstimateAdjuster: GlobalGoalEstimateAdjuster {
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

        func adjust(_ item: GlobalGoalEstimate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SourceGlobalGoalEstimateAdjuster: GlobalGoalEstimateAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: GlobalGoalEstimate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the global goal estimate steps in order and keeps a trace of each.
    final class GlobalGoalEstimateEngine {
        var steps: [any GlobalGoalEstimateAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalGoalEstimateAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: GlobalGoalEstimate) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalGoalEstimateAdjuster = steps[index]
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

        func evaluateAll(_ items: [GlobalGoalEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultGlobalGoalEstimateEngine(_ flags: Kit.Flags.Registry) -> GlobalGoalEstimateEngine {
        return GlobalGoalEstimateEngine(
            steps: [
                RoundingGlobalGoalEstimateAdjuster(step: 1.0),
                FlaggedGlobalGoalEstimateAdjuster(flags: flags, flag: "global-goal-estimate-batched", percent: -2.0),
                SourceGlobalGoalEstimateAdjuster(factors: ["central": 1.23]),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 89457.3
        )
    }
}
