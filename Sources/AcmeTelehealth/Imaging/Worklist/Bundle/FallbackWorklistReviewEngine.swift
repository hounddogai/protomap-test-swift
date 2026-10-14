import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the fallback worklist review calculation.
    protocol FallbackWorklistReviewModifier {
        func describe() -> String
        func adjust(_ item: FallbackWorklistReview, value: Double) -> Double
    }

    final class FlaggedFallbackWorklistReviewAdjuster: FallbackWorklistReviewModifier {
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

        func adjust(_ item: FallbackWorklistReview, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameFallbackWorklistReviewAdjuster: FallbackWorklistReviewModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: FallbackWorklistReview, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingFallbackWorklistReviewAdjuster: FallbackWorklistReviewModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackWorklistReview, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the fallback worklist review steps in order and keeps a trace of each.
    final class FallbackWorklistReviewEngine {
        var steps: [any FallbackWorklistReviewModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackWorklistReviewModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FallbackWorklistReview) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackWorklistReviewModifier = steps[index]
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

        func evaluateAll(_ items: [FallbackWorklistReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFallbackWorklistReviewEngine(_ flags: Kit.Flags.Registry) -> FallbackWorklistReviewEngine {
        return FallbackWorklistReviewEngine(
            steps: [
                FlaggedFallbackWorklistReviewAdjuster(
                    flags: flags,
                    flag: "fallback-worklist-review-batched",
                    percent: -4.7
                ),
                NameFallbackWorklistReviewAdjuster(factors: ["south": 0.77, "east": 0.96]),
                RoundingFallbackWorklistReviewAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 10138.7
        )
    }
}
