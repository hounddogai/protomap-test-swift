import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the manual closure review calculation.
    protocol ManualClosureReviewFactor {
        func describe() -> String
        func adjust(_ item: ManualClosureReview, value: Double) -> Double
    }

    final class ManualClosureReviewScoreOffsetAdjuster: ManualClosureReviewFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: ManualClosureReview, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class RoundingManualClosureReviewAdjuster: ManualClosureReviewFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualClosureReview, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredManualClosureReviewAdjuster: ManualClosureReviewFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualClosureReview, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedManualClosureReviewAdjuster: ManualClosureReviewFactor {
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

        func adjust(_ item: ManualClosureReview, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentManualClosureReviewAdjuster: ManualClosureReviewFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualClosureReview, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapManualClosureReviewAdjuster: ManualClosureReviewFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualClosureReview, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the manual closure review steps in order and keeps a trace of each.
    final class ManualClosureReviewEngine {
        var steps: [any ManualClosureReviewFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualClosureReviewFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ManualClosureReview) -> Double {
            var current = item.projectedLoad()
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

        func evaluateAll(_ items: [ManualClosureReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultManualClosureReviewEngine(_ flags: Kit.Flags.Registry) -> ManualClosureReviewEngine {
        return ManualClosureReviewEngine(
            steps: [
                ManualClosureReviewScoreOffsetAdjuster(weight: 1.05),
                RoundingManualClosureReviewAdjuster(step: 0.25),
                TieredManualClosureReviewAdjuster(
                    bounds: [859.0, 7782.0, 7826.0, 8535.0],
                    rates: [0.89, 1.01, 1.03, 0.95]
                ),
                FlaggedManualClosureReviewAdjuster(flags: flags, flag: "manual-closure-review-strict", percent: 7.8),
                PercentManualClosureReviewAdjuster(percent: -3.8),
                CapManualClosureReviewAdjuster(cap: 23497.0),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 71374.4
        )
    }
}
