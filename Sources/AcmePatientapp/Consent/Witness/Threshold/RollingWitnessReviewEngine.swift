import AcmePlatform
import Foundation

extension Consent {
    /// One step of the rolling witness review calculation.
    protocol RollingWitnessReviewModifier {
        func describe() -> String
        func adjust(_ item: RollingWitnessReview, value: Double) -> Double
    }

    final class TieredRollingWitnessReviewAdjuster: RollingWitnessReviewModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingWitnessReview, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedRollingWitnessReviewAdjuster: RollingWitnessReviewModifier {
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

        func adjust(_ item: RollingWitnessReview, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RollingWitnessReviewDurationMinutesOffsetAdjuster: RollingWitnessReviewModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus duration minutes times \(weight)"
        }

        func adjust(_ item: RollingWitnessReview, value: Double) -> Double {
            return value + Double(item.durationMinutes) * weight
        }
    }

    /// Runs the rolling witness review steps in order and keeps a trace of each.
    final class RollingWitnessReviewEngine {
        var steps: [any RollingWitnessReviewModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingWitnessReviewModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RollingWitnessReview) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingWitnessReviewModifier = steps[index]
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

        func evaluateAll(_ items: [RollingWitnessReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRollingWitnessReviewEngine(_ flags: Kit.Flags.Registry) -> RollingWitnessReviewEngine {
        return RollingWitnessReviewEngine(
            steps: [
                TieredRollingWitnessReviewAdjuster(
                    bounds: [281.0, 320.0, 6001.0, 8548.0],
                    rates: [0.94, 1.01, 0.98, 0.95]
                ),
                FlaggedRollingWitnessReviewAdjuster(
                    flags: flags,
                    flag: "rolling-witness-review-scheduled",
                    percent: 1.0
                ),
                RollingWitnessReviewDurationMinutesOffsetAdjuster(weight: 0.85),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 8684.1
        )
    }
}
