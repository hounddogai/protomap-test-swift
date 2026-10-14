import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the rolling care gap review calculation.
    protocol RollingCareGapReviewAdjuster {
        func describe() -> String
        func adjust(_ item: RollingCareGapReview, value: Double) -> Double
    }

    final class FlaggedRollingCareGapReviewAdjuster: RollingCareGapReviewAdjuster {
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

        func adjust(_ item: RollingCareGapReview, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentRollingCareGapReviewAdjuster: RollingCareGapReviewAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingCareGapReview, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapRollingCareGapReviewAdjuster: RollingCareGapReviewAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingCareGapReview, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RollingCareGapReviewCapacityOffsetAdjuster: RollingCareGapReviewAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: RollingCareGapReview, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    final class RoundingRollingCareGapReviewAdjuster: RollingCareGapReviewAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingCareGapReview, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class ChannelRollingCareGapReviewAdjuster: RollingCareGapReviewAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: RollingCareGapReview, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the rolling care gap review steps in order and keeps a trace of each.
    final class RollingCareGapReviewEngine {
        var steps: [any RollingCareGapReviewAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingCareGapReviewAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RollingCareGapReview) -> Double {
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

        func evaluateAll(_ items: [RollingCareGapReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRollingCareGapReviewEngine(_ flags: Kit.Flags.Registry) -> RollingCareGapReviewEngine {
        return RollingCareGapReviewEngine(
            steps: [
                FlaggedRollingCareGapReviewAdjuster(
                    flags: flags,
                    flag: "rolling-care-gap-review-fallback",
                    percent: 4.5
                ),
                PercentRollingCareGapReviewAdjuster(percent: -5.0),
                CapRollingCareGapReviewAdjuster(cap: 16154.0),
                RollingCareGapReviewCapacityOffsetAdjuster(weight: 0.25),
                RoundingRollingCareGapReviewAdjuster(step: 5.0),
                ChannelRollingCareGapReviewAdjuster(factors: ["west": 0.96, "south": 1.21, "central": 0.99]),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 53715.1
        )
    }
}
