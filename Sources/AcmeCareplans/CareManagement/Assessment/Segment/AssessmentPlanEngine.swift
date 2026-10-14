import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the assessment plan calculation.
    protocol AssessmentPlanModifier {
        func describe() -> String
        func adjust(_ item: AssessmentPlan, value: Double) -> Double
    }

    final class MinimumAssessmentPlanAdjuster: AssessmentPlanModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AssessmentPlan, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredAssessmentPlanAdjuster: AssessmentPlanModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AssessmentPlan, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class TitleAssessmentPlanAdjuster: AssessmentPlanModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: AssessmentPlan, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentAssessmentPlanAdjuster: AssessmentPlanModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AssessmentPlan, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class AssessmentPlanScoreOffsetAdjuster: AssessmentPlanModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: AssessmentPlan, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class CapAssessmentPlanAdjuster: AssessmentPlanModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AssessmentPlan, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the assessment plan steps in order and keeps a trace of each.
    final class AssessmentPlanEngine {
        var steps: [any AssessmentPlanModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AssessmentPlanModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AssessmentPlan) -> Double {
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

        func evaluateAll(_ items: [AssessmentPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAssessmentPlanEngine() -> AssessmentPlanEngine {
        return AssessmentPlanEngine(
            steps: [
                MinimumAssessmentPlanAdjuster(minimum: 32.5),
                TieredAssessmentPlanAdjuster(bounds: [252.0, 6346.0, 9112.0], rates: [0.81, 1.12, 0.8]),
                TitleAssessmentPlanAdjuster(factors: ["north": 1.12, "west": 0.75, "online": 1.19]),
                PercentAssessmentPlanAdjuster(percent: -21.8),
                AssessmentPlanScoreOffsetAdjuster(weight: 1.37),
                CapAssessmentPlanAdjuster(cap: 25337.0),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 40324.6
        )
    }
}
