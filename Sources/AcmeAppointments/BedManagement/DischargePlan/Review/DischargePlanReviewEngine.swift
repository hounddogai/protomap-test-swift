import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the discharge plan review calculation.
    protocol DischargePlanReviewAdjuster {
        func describe() -> String
        func adjust(_ item: DischargePlanReview, value: Double) -> Double
    }

    final class FlaggedDischargePlanReviewAdjuster: DischargePlanReviewAdjuster {
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

        func adjust(_ item: DischargePlanReview, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapDischargePlanReviewAdjuster: DischargePlanReviewAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DischargePlanReview, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class DischargePlanReviewVersionOffsetAdjuster: DischargePlanReviewAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus version times \(weight)"
        }

        func adjust(_ item: DischargePlanReview, value: Double) -> Double {
            return value + Double(item.version) * weight
        }
    }

    final class PercentDischargePlanReviewAdjuster: DischargePlanReviewAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DischargePlanReview, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumDischargePlanReviewAdjuster: DischargePlanReviewAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DischargePlanReview, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TitleDischargePlanReviewAdjuster: DischargePlanReviewAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: DischargePlanReview, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the discharge plan review steps in order and keeps a trace of each.
    final class DischargePlanReviewEngine {
        var steps: [any DischargePlanReviewAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DischargePlanReviewAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DischargePlanReview) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any DischargePlanReviewAdjuster = steps[index]
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

        func evaluateAll(_ items: [DischargePlanReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDischargePlanReviewEngine(_ flags: Kit.Flags.Registry) -> DischargePlanReviewEngine {
        return DischargePlanReviewEngine(
            steps: [
                FlaggedDischargePlanReviewAdjuster(flags: flags, flag: "discharge-plan-review-rolling", percent: 3.0),
                CapDischargePlanReviewAdjuster(cap: 4377.0),
                DischargePlanReviewVersionOffsetAdjuster(weight: 1.09),
                PercentDischargePlanReviewAdjuster(percent: -6.2),
                MinimumDischargePlanReviewAdjuster(minimum: 12.7),
                TitleDischargePlanReviewAdjuster(factors: ["central": 1.27]),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 78061.9
        )
    }
}
