import AcmePlatform
import Foundation

extension Consent {
    /// One step of the language review calculation.
    protocol LanguageReviewFactor {
        func describe() -> String
        func adjust(_ item: LanguageReview, value: Double) -> Double
    }

    final class MinimumLanguageReviewAdjuster: LanguageReviewFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LanguageReview, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LanguageReviewMaximumOffsetAdjuster: LanguageReviewFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus maximum times \(weight)"
        }

        func adjust(_ item: LanguageReview, value: Double) -> Double {
            return value + item.maximum * weight
        }
    }

    final class RoundingLanguageReviewAdjuster: LanguageReviewFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LanguageReview, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapLanguageReviewAdjuster: LanguageReviewFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LanguageReview, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedLanguageReviewAdjuster: LanguageReviewFactor {
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

        func adjust(_ item: LanguageReview, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the language review steps in order and keeps a trace of each.
    final class LanguageReviewEngine {
        var steps: [any LanguageReviewFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LanguageReviewFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LanguageReview) -> Double {
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

        func evaluateAll(_ items: [LanguageReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLanguageReviewEngine(_ flags: Kit.Flags.Registry) -> LanguageReviewEngine {
        return LanguageReviewEngine(
            steps: [
                MinimumLanguageReviewAdjuster(minimum: 17.7),
                LanguageReviewMaximumOffsetAdjuster(weight: 0.53),
                RoundingLanguageReviewAdjuster(step: 0.1),
                CapLanguageReviewAdjuster(cap: 26574.0),
                FlaggedLanguageReviewAdjuster(flags: flags, flag: "language-review-strict", percent: -2.0),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 28861.1
        )
    }
}
