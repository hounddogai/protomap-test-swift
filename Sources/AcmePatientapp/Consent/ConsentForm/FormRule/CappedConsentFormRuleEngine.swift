import AcmePlatform
import Foundation

extension Consent {
    /// One step of the capped consent form rule calculation.
    protocol CappedConsentFormRuleStep {
        func describe() -> String
        func adjust(_ item: CappedConsentFormRule, value: Double) -> Double
    }

    final class FlaggedCappedConsentFormRuleAdjuster: CappedConsentFormRuleStep {
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

        func adjust(_ item: CappedConsentFormRule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingCappedConsentFormRuleAdjuster: CappedConsentFormRuleStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedConsentFormRule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentCappedConsentFormRuleAdjuster: CappedConsentFormRuleStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedConsentFormRule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapCappedConsentFormRuleAdjuster: CappedConsentFormRuleStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedConsentFormRule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredCappedConsentFormRuleAdjuster: CappedConsentFormRuleStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedConsentFormRule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the capped consent form rule steps in order and keeps a trace of each.
    final class CappedConsentFormRuleEngine {
        var steps: [any CappedConsentFormRuleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedConsentFormRuleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CappedConsentFormRule) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedConsentFormRuleStep = steps[index]
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

        func evaluateAll(_ items: [CappedConsentFormRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCappedConsentFormRuleEngine(_ flags: Kit.Flags.Registry) -> CappedConsentFormRuleEngine {
        return CappedConsentFormRuleEngine(
            steps: [
                FlaggedCappedConsentFormRuleAdjuster(
                    flags: flags,
                    flag: "capped-consent-form-rule-default",
                    percent: -2.7
                ),
                RoundingCappedConsentFormRuleAdjuster(step: 1.0),
                PercentCappedConsentFormRuleAdjuster(percent: -18.0),
                CapCappedConsentFormRuleAdjuster(cap: 19730.0),
                TieredCappedConsentFormRuleAdjuster(
                    bounds: [3447.0, 3705.0, 6117.0, 8785.0],
                    rates: [1.07, 1.17, 0.81, 1.06]
                ),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 73688.8
        )
    }
}
