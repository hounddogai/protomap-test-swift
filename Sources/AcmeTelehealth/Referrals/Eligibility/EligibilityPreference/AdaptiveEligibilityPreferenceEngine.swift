import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the adaptive eligibility preference calculation.
    protocol AdaptiveEligibilityPreferenceModifier {
        func describe() -> String
        func adjust(_ item: AdaptiveEligibilityPreference, value: Double) -> Double
    }

    final class PercentAdaptiveEligibilityPreferenceAdjuster: AdaptiveEligibilityPreferenceModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveEligibilityPreference, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapAdaptiveEligibilityPreferenceAdjuster: AdaptiveEligibilityPreferenceModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveEligibilityPreference, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedAdaptiveEligibilityPreferenceAdjuster: AdaptiveEligibilityPreferenceModifier {
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

        func adjust(_ item: AdaptiveEligibilityPreference, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CountryAdaptiveEligibilityPreferenceAdjuster: AdaptiveEligibilityPreferenceModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: AdaptiveEligibilityPreference, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingAdaptiveEligibilityPreferenceAdjuster: AdaptiveEligibilityPreferenceModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveEligibilityPreference, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the adaptive eligibility preference steps in order and keeps a trace of each.
    final class AdaptiveEligibilityPreferenceEngine {
        var steps: [any AdaptiveEligibilityPreferenceModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveEligibilityPreferenceModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AdaptiveEligibilityPreference) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveEligibilityPreferenceModifier = steps[index]
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

        func evaluateAll(_ items: [AdaptiveEligibilityPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAdaptiveEligibilityPreferenceEngine(_ flags: Kit.Flags.Registry) -> AdaptiveEligibilityPreferenceEngine {
        return AdaptiveEligibilityPreferenceEngine(
            steps: [
                PercentAdaptiveEligibilityPreferenceAdjuster(percent: 4.0),
                CapAdaptiveEligibilityPreferenceAdjuster(cap: 14101.0),
                FlaggedAdaptiveEligibilityPreferenceAdjuster(
                    flags: flags,
                    flag: "adaptive-eligibility-preference-lenient",
                    percent: 8.2
                ),
                CountryAdaptiveEligibilityPreferenceAdjuster(factors: ["online": 0.86, "west": 1.03]),
                RoundingAdaptiveEligibilityPreferenceAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 96727.4
        )
    }
}
