import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the strict skill mix review calculation.
    protocol StrictSkillMixReviewModifier {
        func describe() -> String
        func adjust(_ item: StrictSkillMixReview, value: Double) -> Double
    }

    final class SegmentStrictSkillMixReviewAdjuster: StrictSkillMixReviewModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: StrictSkillMixReview, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class StrictSkillMixReviewDurationMinutesOffsetAdjuster: StrictSkillMixReviewModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus duration minutes times \(weight)"
        }

        func adjust(_ item: StrictSkillMixReview, value: Double) -> Double {
            return value + Double(item.durationMinutes) * weight
        }
    }

    final class MinimumStrictSkillMixReviewAdjuster: StrictSkillMixReviewModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictSkillMixReview, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingStrictSkillMixReviewAdjuster: StrictSkillMixReviewModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictSkillMixReview, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapStrictSkillMixReviewAdjuster: StrictSkillMixReviewModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictSkillMixReview, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the strict skill mix review steps in order and keeps a trace of each.
    final class StrictSkillMixReviewEngine {
        var steps: [any StrictSkillMixReviewModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictSkillMixReviewModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: StrictSkillMixReview) -> Double {
            var current = item.netExposure()
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

        func evaluateAll(_ items: [StrictSkillMixReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultStrictSkillMixReviewEngine() -> StrictSkillMixReviewEngine {
        return StrictSkillMixReviewEngine(
            steps: [
                SegmentStrictSkillMixReviewAdjuster(factors: ["east": 0.75, "online": 1.03, "retail": 0.92]),
                StrictSkillMixReviewDurationMinutesOffsetAdjuster(weight: 1.05),
                MinimumStrictSkillMixReviewAdjuster(minimum: 37.0),
                RoundingStrictSkillMixReviewAdjuster(step: 5.0),
                CapStrictSkillMixReviewAdjuster(cap: 9594.0),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 4034.4
        )
    }
}
