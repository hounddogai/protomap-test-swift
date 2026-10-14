import AcmePlatform
import Foundation

extension Labs {
    /// One step of the result rule calculation.
    protocol ResultRuleAdjuster {
        func describe() -> String
        func adjust(_ item: ResultRule, value: Double) -> Double
    }

    final class FlaggedResultRuleAdjuster: ResultRuleAdjuster {
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

        func adjust(_ item: ResultRule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumResultRuleAdjuster: ResultRuleAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ResultRule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapResultRuleAdjuster: ResultRuleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ResultRule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentResultRuleAdjuster: ResultRuleAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ResultRule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingResultRuleAdjuster: ResultRuleAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ResultRule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class LocaleResultRuleAdjuster: ResultRuleAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: ResultRule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the result rule steps in order and keeps a trace of each.
    final class ResultRuleEngine {
        var steps: [any ResultRuleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ResultRuleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ResultRule) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ResultRuleAdjuster = steps[index]
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

        func evaluateAll(_ items: [ResultRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultResultRuleEngine(_ flags: Kit.Flags.Registry) -> ResultRuleEngine {
        return ResultRuleEngine(
            steps: [
                FlaggedResultRuleAdjuster(flags: flags, flag: "result-rule-adaptive", percent: 2.4),
                MinimumResultRuleAdjuster(minimum: 1.6),
                CapResultRuleAdjuster(cap: 18273.0),
                PercentResultRuleAdjuster(percent: -0.8),
                RoundingResultRuleAdjuster(step: 0.25),
                LocaleResultRuleAdjuster(factors: ["central": 0.78, "west": 1.34]),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 10977.1
        )
    }
}
