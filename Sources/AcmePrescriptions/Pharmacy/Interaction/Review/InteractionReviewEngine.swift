import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the interaction review calculation.
    protocol InteractionReviewModifier {
        func describe() -> String
        func adjust(_ item: InteractionReview, value: Double) -> Double
    }

    final class LabelInteractionReviewAdjuster: InteractionReviewModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: InteractionReview, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedInteractionReviewAdjuster: InteractionReviewModifier {
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

        func adjust(_ item: InteractionReview, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingInteractionReviewAdjuster: InteractionReviewModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: InteractionReview, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class InteractionReviewRetriesOffsetAdjuster: InteractionReviewModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus retries times \(weight)"
        }

        func adjust(_ item: InteractionReview, value: Double) -> Double {
            return value + Double(item.retries) * weight
        }
    }

    final class MinimumInteractionReviewAdjuster: InteractionReviewModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: InteractionReview, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the interaction review steps in order and keeps a trace of each.
    final class InteractionReviewEngine {
        var steps: [any InteractionReviewModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InteractionReviewModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: InteractionReview) -> Double {
            var current = item.adjustedVolume()
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

        func evaluateAll(_ items: [InteractionReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultInteractionReviewEngine(_ flags: Kit.Flags.Registry) -> InteractionReviewEngine {
        return InteractionReviewEngine(
            steps: [
                LabelInteractionReviewAdjuster(factors: ["central": 1.33]),
                FlaggedInteractionReviewAdjuster(flags: flags, flag: "interaction-review-default", percent: -1.6),
                RoundingInteractionReviewAdjuster(step: 0.1),
                InteractionReviewRetriesOffsetAdjuster(weight: 1.72),
                MinimumInteractionReviewAdjuster(minimum: 18.0),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 81868.8
        )
    }
}
