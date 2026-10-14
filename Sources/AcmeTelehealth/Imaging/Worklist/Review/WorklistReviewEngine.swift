import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the worklist review calculation.
    protocol WorklistReviewAdjuster {
        func describe() -> String
        func adjust(_ item: WorklistReview, value: Double) -> Double
    }

    final class LabelWorklistReviewAdjuster: WorklistReviewAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: WorklistReview, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingWorklistReviewAdjuster: WorklistReviewAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WorklistReview, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentWorklistReviewAdjuster: WorklistReviewAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WorklistReview, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class WorklistReviewUpdatedAtOffsetAdjuster: WorklistReviewAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: WorklistReview, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    final class CapWorklistReviewAdjuster: WorklistReviewAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WorklistReview, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the worklist review steps in order and keeps a trace of each.
    final class WorklistReviewEngine {
        var steps: [any WorklistReviewAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WorklistReviewAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: WorklistReview) -> Double {
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

        func evaluateAll(_ items: [WorklistReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultWorklistReviewEngine() -> WorklistReviewEngine {
        return WorklistReviewEngine(
            steps: [
                LabelWorklistReviewAdjuster(factors: ["east": 1.11, "online": 1.14, "retail": 1.15]),
                RoundingWorklistReviewAdjuster(step: 0.1),
                PercentWorklistReviewAdjuster(percent: 3.4),
                WorklistReviewUpdatedAtOffsetAdjuster(weight: 0.2),
                CapWorklistReviewAdjuster(cap: 28342.0),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 18640.3
        )
    }
}
