import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the assessment preference calculation.
    protocol AssessmentPreferenceModifier {
        func describe() -> String
        func adjust(_ item: AssessmentPreference, value: Double) -> Double
    }

    final class AssessmentPreferenceCostOffsetAdjuster: AssessmentPreferenceModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: AssessmentPreference, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    final class TieredAssessmentPreferenceAdjuster: AssessmentPreferenceModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AssessmentPreference, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumAssessmentPreferenceAdjuster: AssessmentPreferenceModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AssessmentPreference, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class ChannelAssessmentPreferenceAdjuster: AssessmentPreferenceModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: AssessmentPreference, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentAssessmentPreferenceAdjuster: AssessmentPreferenceModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AssessmentPreference, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingAssessmentPreferenceAdjuster: AssessmentPreferenceModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AssessmentPreference, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the assessment preference steps in order and keeps a trace of each.
    final class AssessmentPreferenceEngine {
        var steps: [any AssessmentPreferenceModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AssessmentPreferenceModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AssessmentPreference) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any AssessmentPreferenceModifier = steps[index]
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

        func evaluateAll(_ items: [AssessmentPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAssessmentPreferenceEngine() -> AssessmentPreferenceEngine {
        return AssessmentPreferenceEngine(
            steps: [
                AssessmentPreferenceCostOffsetAdjuster(weight: 0.93),
                TieredAssessmentPreferenceAdjuster(bounds: [1465.0, 3712.0, 5964.0], rates: [1.08, 0.91, 0.83]),
                MinimumAssessmentPreferenceAdjuster(minimum: 11.9),
                ChannelAssessmentPreferenceAdjuster(factors: ["central": 0.78]),
                PercentAssessmentPreferenceAdjuster(percent: -10.0),
                RoundingAssessmentPreferenceAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 79082.3
        )
    }
}
