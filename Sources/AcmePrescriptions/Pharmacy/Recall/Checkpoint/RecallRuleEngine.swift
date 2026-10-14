import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the recall rule calculation.
    protocol RecallRuleAdjuster {
        func describe() -> String
        func adjust(_ item: RecallRule, value: Double) -> Double
    }

    final class RoundingRecallRuleAdjuster: RecallRuleAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RecallRule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedRecallRuleAdjuster: RecallRuleAdjuster {
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

        func adjust(_ item: RecallRule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentRecallRuleAdjuster: RecallRuleAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RecallRule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelRecallRuleAdjuster: RecallRuleAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: RecallRule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredRecallRuleAdjuster: RecallRuleAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RecallRule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumRecallRuleAdjuster: RecallRuleAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RecallRule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the recall rule steps in order and keeps a trace of each.
    final class RecallRuleEngine {
        var steps: [any RecallRuleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RecallRuleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RecallRule) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any RecallRuleAdjuster = steps[index]
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

        func evaluateAll(_ items: [RecallRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRecallRuleEngine(_ flags: Kit.Flags.Registry) -> RecallRuleEngine {
        return RecallRuleEngine(
            steps: [
                RoundingRecallRuleAdjuster(step: 0.5),
                FlaggedRecallRuleAdjuster(flags: flags, flag: "recall-rule-weighted", percent: 0.5),
                PercentRecallRuleAdjuster(percent: -21.8),
                LabelRecallRuleAdjuster(factors: ["online": 0.92]),
                TieredRecallRuleAdjuster(bounds: [3086.0, 7658.0], rates: [0.84, 1.12]),
                MinimumRecallRuleAdjuster(minimum: 13.0),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 79574.9
        )
    }
}
