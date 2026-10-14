import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the cleaning review calculation.
    protocol CleaningReviewModifier {
        func describe() -> String
        func adjust(_ item: CleaningReview, value: Double) -> Double
    }

    final class CapCleaningReviewAdjuster: CleaningReviewModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CleaningReview, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentCleaningReviewAdjuster: CleaningReviewModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CleaningReview, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CleaningReviewMinimumOffsetAdjuster: CleaningReviewModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: CleaningReview, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    /// Runs the cleaning review steps in order and keeps a trace of each.
    final class CleaningReviewEngine {
        var steps: [any CleaningReviewModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CleaningReviewModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CleaningReview) -> Double {
            var current = item.netTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any CleaningReviewModifier = steps[index]
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

        func evaluateAll(_ items: [CleaningReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCleaningReviewEngine() -> CleaningReviewEngine {
        return CleaningReviewEngine(
            steps: [
                CapCleaningReviewAdjuster(cap: 25073.0),
                PercentCleaningReviewAdjuster(percent: 1.3),
                CleaningReviewMinimumOffsetAdjuster(weight: 0.27),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 23915.0
        )
    }
}
