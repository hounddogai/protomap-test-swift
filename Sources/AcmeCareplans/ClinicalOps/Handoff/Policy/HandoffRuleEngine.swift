import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the handoff rule calculation.
    protocol HandoffRuleStep {
        func describe() -> String
        func adjust(_ item: HandoffRule, value: Double) -> Double
    }

    final class PercentHandoffRuleAdjuster: HandoffRuleStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: HandoffRule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumHandoffRuleAdjuster: HandoffRuleStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: HandoffRule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LabelHandoffRuleAdjuster: HandoffRuleStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: HandoffRule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapHandoffRuleAdjuster: HandoffRuleStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: HandoffRule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedHandoffRuleAdjuster: HandoffRuleStep {
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

        func adjust(_ item: HandoffRule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the handoff rule steps in order and keeps a trace of each.
    final class HandoffRuleEngine {
        var steps: [any HandoffRuleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any HandoffRuleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: HandoffRule) -> Double {
            var current = item.projectedLoad()
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

        func evaluateAll(_ items: [HandoffRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultHandoffRuleEngine(_ flags: Kit.Flags.Registry) -> HandoffRuleEngine {
        return HandoffRuleEngine(
            steps: [
                PercentHandoffRuleAdjuster(percent: -6.8),
                MinimumHandoffRuleAdjuster(minimum: 20.1),
                LabelHandoffRuleAdjuster(factors: ["east": 0.96]),
                CapHandoffRuleAdjuster(cap: 20377.0),
                FlaggedHandoffRuleAdjuster(flags: flags, flag: "handoff-rule-manual", percent: -0.6),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 34443.6
        )
    }
}
