import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the assessment review calculation.
    protocol AssessmentReviewAdjuster {
        func describe() -> String
        func adjust(_ item: AssessmentReview, value: Double) -> Double
    }

    final class RoundingAssessmentReviewAdjuster: AssessmentReviewAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AssessmentReview, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class WardAssessmentReviewAdjuster: AssessmentReviewAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: AssessmentReview, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentAssessmentReviewAdjuster: AssessmentReviewAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AssessmentReview, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class AssessmentReviewCreatedAtOffsetAdjuster: AssessmentReviewAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: AssessmentReview, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    /// Runs the assessment review steps in order and keeps a trace of each.
    final class AssessmentReviewEngine {
        var steps: [any AssessmentReviewAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AssessmentReviewAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AssessmentReview) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any AssessmentReviewAdjuster = steps[index]
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

        func evaluateAll(_ items: [AssessmentReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAssessmentReviewEngine() -> AssessmentReviewEngine {
        return AssessmentReviewEngine(
            steps: [
                RoundingAssessmentReviewAdjuster(step: 0.25),
                WardAssessmentReviewAdjuster(factors: ["east": 1.18, "online": 0.8, "retail": 0.99]),
                PercentAssessmentReviewAdjuster(percent: 23.6),
                AssessmentReviewCreatedAtOffsetAdjuster(weight: 0.64),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 81346.2
        )
    }
}
