import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the care protocol review calculation.
    protocol CareProtocolReviewModifier {
        func describe() -> String
        func adjust(_ item: CareProtocolReview, value: Double) -> Double
    }

    final class CapCareProtocolReviewAdjuster: CareProtocolReviewModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CareProtocolReview, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentCareProtocolReviewAdjuster: CareProtocolReviewModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CareProtocolReview, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedCareProtocolReviewAdjuster: CareProtocolReviewModifier {
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

        func adjust(_ item: CareProtocolReview, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingCareProtocolReviewAdjuster: CareProtocolReviewModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CareProtocolReview, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumCareProtocolReviewAdjuster: CareProtocolReviewModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CareProtocolReview, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LabelCareProtocolReviewAdjuster: CareProtocolReviewModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: CareProtocolReview, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the care protocol review steps in order and keeps a trace of each.
    final class CareProtocolReviewEngine {
        var steps: [any CareProtocolReviewModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareProtocolReviewModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CareProtocolReview) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any CareProtocolReviewModifier = steps[index]
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

        func evaluateAll(_ items: [CareProtocolReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCareProtocolReviewEngine(_ flags: Kit.Flags.Registry) -> CareProtocolReviewEngine {
        return CareProtocolReviewEngine(
            steps: [
                CapCareProtocolReviewAdjuster(cap: 27455.0),
                PercentCareProtocolReviewAdjuster(percent: 21.1),
                FlaggedCareProtocolReviewAdjuster(flags: flags, flag: "care-protocol-review-tiered", percent: -9.5),
                RoundingCareProtocolReviewAdjuster(step: 5.0),
                MinimumCareProtocolReviewAdjuster(minimum: 12.8),
                LabelCareProtocolReviewAdjuster(factors: ["south": 1.04, "north": 1.07]),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 64424.4
        )
    }
}
