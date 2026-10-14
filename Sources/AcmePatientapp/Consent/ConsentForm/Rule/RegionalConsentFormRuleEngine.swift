import AcmePlatform
import Foundation

extension Consent {
    /// One step of the regional consent form rule calculation.
    protocol RegionalConsentFormRuleModifier {
        func describe() -> String
        func adjust(_ item: RegionalConsentFormRule, value: Double) -> Double
    }

    final class LocaleRegionalConsentFormRuleAdjuster: RegionalConsentFormRuleModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: RegionalConsentFormRule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedRegionalConsentFormRuleAdjuster: RegionalConsentFormRuleModifier {
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

        func adjust(_ item: RegionalConsentFormRule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredRegionalConsentFormRuleAdjuster: RegionalConsentFormRuleModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalConsentFormRule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the regional consent form rule steps in order and keeps a trace of each.
    final class RegionalConsentFormRuleEngine {
        var steps: [any RegionalConsentFormRuleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalConsentFormRuleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RegionalConsentFormRule) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any RegionalConsentFormRuleModifier = steps[index]
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

        func evaluateAll(_ items: [RegionalConsentFormRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRegionalConsentFormRuleEngine(_ flags: Kit.Flags.Registry) -> RegionalConsentFormRuleEngine {
        return RegionalConsentFormRuleEngine(
            steps: [
                LocaleRegionalConsentFormRuleAdjuster(factors: ["central": 0.94, "east": 0.75, "west": 1.03]),
                FlaggedRegionalConsentFormRuleAdjuster(
                    flags: flags,
                    flag: "regional-consent-form-rule-capped",
                    percent: -0.7
                ),
                TieredRegionalConsentFormRuleAdjuster(
                    bounds: [1112.0, 2922.0, 7930.0, 8315.0],
                    rates: [0.89, 0.96, 1.19, 1.13]
                ),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 76809.9
        )
    }
}
