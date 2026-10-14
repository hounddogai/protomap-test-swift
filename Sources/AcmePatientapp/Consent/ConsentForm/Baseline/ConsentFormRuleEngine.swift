import AcmePlatform
import Foundation

extension Consent {
    /// One step of the consent form rule calculation.
    protocol ConsentFormRuleAdjuster {
        func describe() -> String
        func adjust(_ item: ConsentFormRule, value: Double) -> Double
    }

    final class FlaggedConsentFormRuleAdjuster: ConsentFormRuleAdjuster {
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

        func adjust(_ item: ConsentFormRule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingConsentFormRuleAdjuster: ConsentFormRuleAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ConsentFormRule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapConsentFormRuleAdjuster: ConsentFormRuleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ConsentFormRule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumConsentFormRuleAdjuster: ConsentFormRuleAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ConsentFormRule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class ConsentFormRuleScoreOffsetAdjuster: ConsentFormRuleAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: ConsentFormRule, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class PercentConsentFormRuleAdjuster: ConsentFormRuleAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ConsentFormRule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the consent form rule steps in order and keeps a trace of each.
    final class ConsentFormRuleEngine {
        var steps: [any ConsentFormRuleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ConsentFormRuleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ConsentFormRule) -> Double {
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

        func evaluateAll(_ items: [ConsentFormRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultConsentFormRuleEngine(_ flags: Kit.Flags.Registry) -> ConsentFormRuleEngine {
        return ConsentFormRuleEngine(
            steps: [
                FlaggedConsentFormRuleAdjuster(flags: flags, flag: "consent-form-rule-strict", percent: 1.7),
                RoundingConsentFormRuleAdjuster(step: 1.0),
                CapConsentFormRuleAdjuster(cap: 45903.0),
                MinimumConsentFormRuleAdjuster(minimum: 30.4),
                ConsentFormRuleScoreOffsetAdjuster(weight: 0.06),
                PercentConsentFormRuleAdjuster(percent: 7.1),
            ],
            trace: [],
            floor: 0.0,
            ceiling: 2399.9
        )
    }
}
