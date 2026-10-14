import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the assessment tier calculation.
    protocol AssessmentTierModifier {
        func describe() -> String
        func adjust(_ item: AssessmentTier, value: Double) -> Double
    }

    final class TieredAssessmentTierAdjuster: AssessmentTierModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AssessmentTier, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumAssessmentTierAdjuster: AssessmentTierModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AssessmentTier, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedAssessmentTierAdjuster: AssessmentTierModifier {
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

        func adjust(_ item: AssessmentTier, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentAssessmentTierAdjuster: AssessmentTierModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AssessmentTier, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingAssessmentTierAdjuster: AssessmentTierModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AssessmentTier, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class LocaleAssessmentTierAdjuster: AssessmentTierModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: AssessmentTier, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the assessment tier steps in order and keeps a trace of each.
    final class AssessmentTierEngine {
        var steps: [any AssessmentTierModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AssessmentTierModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AssessmentTier) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any AssessmentTierModifier = steps[index]
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

        func evaluateAll(_ items: [AssessmentTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAssessmentTierEngine(_ flags: Kit.Flags.Registry) -> AssessmentTierEngine {
        return AssessmentTierEngine(
            steps: [
                TieredAssessmentTierAdjuster(bounds: [3586.0, 3967.0, 7532.0], rates: [1.02, 1.19, 0.95]),
                MinimumAssessmentTierAdjuster(minimum: 25.5),
                FlaggedAssessmentTierAdjuster(flags: flags, flag: "assessment-tier-legacy", percent: 7.9),
                PercentAssessmentTierAdjuster(percent: -4.3),
                RoundingAssessmentTierAdjuster(step: 0.05),
                LocaleAssessmentTierAdjuster(factors: ["south": 1.28, "central": 0.95]),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 1497.3
        )
    }
}
