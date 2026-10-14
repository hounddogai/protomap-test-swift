import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the primary modality review calculation.
    protocol PrimaryModalityReviewStep {
        func describe() -> String
        func adjust(_ item: PrimaryModalityReview, value: Double) -> Double
    }

    final class FlaggedPrimaryModalityReviewAdjuster: PrimaryModalityReviewStep {
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

        func adjust(_ item: PrimaryModalityReview, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitlePrimaryModalityReviewAdjuster: PrimaryModalityReviewStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: PrimaryModalityReview, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumPrimaryModalityReviewAdjuster: PrimaryModalityReviewStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryModalityReview, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the primary modality review steps in order and keeps a trace of each.
    final class PrimaryModalityReviewEngine {
        var steps: [any PrimaryModalityReviewStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryModalityReviewStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PrimaryModalityReview) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimaryModalityReviewStep = steps[index]
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

        func evaluateAll(_ items: [PrimaryModalityReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPrimaryModalityReviewEngine(_ flags: Kit.Flags.Registry) -> PrimaryModalityReviewEngine {
        return PrimaryModalityReviewEngine(
            steps: [
                FlaggedPrimaryModalityReviewAdjuster(
                    flags: flags,
                    flag: "primary-modality-review-strict",
                    percent: -2.0
                ),
                TitlePrimaryModalityReviewAdjuster(factors: ["south": 1.1, "west": 1.14, "retail": 1.19]),
                MinimumPrimaryModalityReviewAdjuster(minimum: 33.6),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 49605.9
        )
    }
}
