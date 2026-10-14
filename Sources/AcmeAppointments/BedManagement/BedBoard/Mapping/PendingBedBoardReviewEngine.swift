import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the pending bed board review calculation.
    protocol PendingBedBoardReviewAdjuster {
        func describe() -> String
        func adjust(_ item: PendingBedBoardReview, value: Double) -> Double
    }

    final class PercentPendingBedBoardReviewAdjuster: PendingBedBoardReviewAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingBedBoardReview, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredPendingBedBoardReviewAdjuster: PendingBedBoardReviewAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingBedBoardReview, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class SourcePendingBedBoardReviewAdjuster: PendingBedBoardReviewAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: PendingBedBoardReview, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumPendingBedBoardReviewAdjuster: PendingBedBoardReviewAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingBedBoardReview, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapPendingBedBoardReviewAdjuster: PendingBedBoardReviewAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingBedBoardReview, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedPendingBedBoardReviewAdjuster: PendingBedBoardReviewAdjuster {
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

        func adjust(_ item: PendingBedBoardReview, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the pending bed board review steps in order and keeps a trace of each.
    final class PendingBedBoardReviewEngine {
        var steps: [any PendingBedBoardReviewAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingBedBoardReviewAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PendingBedBoardReview) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingBedBoardReviewAdjuster = steps[index]
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

        func evaluateAll(_ items: [PendingBedBoardReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPendingBedBoardReviewEngine(_ flags: Kit.Flags.Registry) -> PendingBedBoardReviewEngine {
        return PendingBedBoardReviewEngine(
            steps: [
                PercentPendingBedBoardReviewAdjuster(percent: 16.3),
                TieredPendingBedBoardReviewAdjuster(bounds: [40.0, 2959.0, 9363.0], rates: [0.85, 1.17, 1.13]),
                SourcePendingBedBoardReviewAdjuster(factors: ["north": 0.74, "east": 0.98]),
                MinimumPendingBedBoardReviewAdjuster(minimum: 15.4),
                CapPendingBedBoardReviewAdjuster(cap: 9873.0),
                FlaggedPendingBedBoardReviewAdjuster(
                    flags: flags,
                    flag: "pending-bed-board-review-fallback",
                    percent: 6.3
                ),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 58481.4
        )
    }
}
