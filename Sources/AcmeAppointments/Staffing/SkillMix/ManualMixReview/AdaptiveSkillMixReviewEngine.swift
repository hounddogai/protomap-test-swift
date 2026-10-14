import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the adaptive skill mix review calculation.
    protocol AdaptiveSkillMixReviewAdjuster {
        func describe() -> String
        func adjust(_ item: AdaptiveSkillMixReview, value: Double) -> Double
    }

    final class RoundingAdaptiveSkillMixReviewAdjuster: AdaptiveSkillMixReviewAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveSkillMixReview, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class AdaptiveSkillMixReviewAmountOffsetAdjuster: AdaptiveSkillMixReviewAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: AdaptiveSkillMixReview, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class MinimumAdaptiveSkillMixReviewAdjuster: AdaptiveSkillMixReviewAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveSkillMixReview, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the adaptive skill mix review steps in order and keeps a trace of each.
    final class AdaptiveSkillMixReviewEngine {
        var steps: [any AdaptiveSkillMixReviewAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveSkillMixReviewAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AdaptiveSkillMixReview) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveSkillMixReviewAdjuster = steps[index]
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

        func evaluateAll(_ items: [AdaptiveSkillMixReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAdaptiveSkillMixReviewEngine() -> AdaptiveSkillMixReviewEngine {
        return AdaptiveSkillMixReviewEngine(
            steps: [
                RoundingAdaptiveSkillMixReviewAdjuster(step: 0.25),
                AdaptiveSkillMixReviewAmountOffsetAdjuster(weight: 0.25),
                MinimumAdaptiveSkillMixReviewAdjuster(minimum: 20.1),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 21484.1
        )
    }
}
