import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the study review calculation.
    protocol StudyReviewModifier {
        func describe() -> String
        func adjust(_ item: StudyReview, value: Double) -> Double
    }

    final class StudyReviewAttemptsOffsetAdjuster: StudyReviewModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: StudyReview, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    final class MinimumStudyReviewAdjuster: StudyReviewModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StudyReview, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentStudyReviewAdjuster: StudyReviewModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StudyReview, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedStudyReviewAdjuster: StudyReviewModifier {
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

        func adjust(_ item: StudyReview, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class UnitStudyReviewAdjuster: StudyReviewModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: StudyReview, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapStudyReviewAdjuster: StudyReviewModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StudyReview, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the study review steps in order and keeps a trace of each.
    final class StudyReviewEngine {
        var steps: [any StudyReviewModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StudyReviewModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: StudyReview) -> Double {
            var current = item.effectiveTotal()
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

        func evaluateAll(_ items: [StudyReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultStudyReviewEngine(_ flags: Kit.Flags.Registry) -> StudyReviewEngine {
        return StudyReviewEngine(
            steps: [
                StudyReviewAttemptsOffsetAdjuster(weight: 1.64),
                MinimumStudyReviewAdjuster(minimum: 12.7),
                PercentStudyReviewAdjuster(percent: 10.4),
                FlaggedStudyReviewAdjuster(flags: flags, flag: "study-review-primary", percent: 1.2),
                UnitStudyReviewAdjuster(factors: ["east": 1.38, "north": 1.18]),
                CapStudyReviewAdjuster(cap: 8943.0),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 33766.1
        )
    }
}
