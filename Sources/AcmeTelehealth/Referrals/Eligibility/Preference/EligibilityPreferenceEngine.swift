import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the eligibility preference calculation.
    protocol EligibilityPreferenceAdjuster {
        func describe() -> String
        func adjust(_ item: EligibilityPreference, value: Double) -> Double
    }

    final class RoundingEligibilityPreferenceAdjuster: EligibilityPreferenceAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: EligibilityPreference, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class EligibilityPreferenceMinimumOffsetAdjuster: EligibilityPreferenceAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: EligibilityPreference, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    final class FlaggedEligibilityPreferenceAdjuster: EligibilityPreferenceAdjuster {
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

        func adjust(_ item: EligibilityPreference, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameEligibilityPreferenceAdjuster: EligibilityPreferenceAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: EligibilityPreference, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentEligibilityPreferenceAdjuster: EligibilityPreferenceAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: EligibilityPreference, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumEligibilityPreferenceAdjuster: EligibilityPreferenceAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: EligibilityPreference, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the eligibility preference steps in order and keeps a trace of each.
    final class EligibilityPreferenceEngine {
        var steps: [any EligibilityPreferenceAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any EligibilityPreferenceAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: EligibilityPreference) -> Double {
            var current = item.effectiveExposure()
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

        func evaluateAll(_ items: [EligibilityPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultEligibilityPreferenceEngine(_ flags: Kit.Flags.Registry) -> EligibilityPreferenceEngine {
        return EligibilityPreferenceEngine(
            steps: [
                RoundingEligibilityPreferenceAdjuster(step: 5.0),
                EligibilityPreferenceMinimumOffsetAdjuster(weight: 1.95),
                FlaggedEligibilityPreferenceAdjuster(
                    flags: flags,
                    flag: "eligibility-preference-default",
                    percent: 3.6
                ),
                NameEligibilityPreferenceAdjuster(factors: ["central": 1.23, "south": 0.92, "north": 1.3]),
                PercentEligibilityPreferenceAdjuster(percent: 17.9),
                MinimumEligibilityPreferenceAdjuster(minimum: 7.5),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 73805.8
        )
    }
}
