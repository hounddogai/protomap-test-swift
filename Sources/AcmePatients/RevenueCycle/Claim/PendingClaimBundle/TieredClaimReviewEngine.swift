import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the tiered claim review calculation.
    protocol TieredClaimReviewStep {
        func describe() -> String
        func adjust(_ item: TieredClaimReview, value: Double) -> Double
    }

    final class MinimumTieredClaimReviewAdjuster: TieredClaimReviewStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredClaimReview, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class UnitTieredClaimReviewAdjuster: TieredClaimReviewStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: TieredClaimReview, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedTieredClaimReviewAdjuster: TieredClaimReviewStep {
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

        func adjust(_ item: TieredClaimReview, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the tiered claim review steps in order and keeps a trace of each.
    final class TieredClaimReviewEngine {
        var steps: [any TieredClaimReviewStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredClaimReviewStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: TieredClaimReview) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any TieredClaimReviewStep = steps[index]
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

        func evaluateAll(_ items: [TieredClaimReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultTieredClaimReviewEngine(_ flags: Kit.Flags.Registry) -> TieredClaimReviewEngine {
        return TieredClaimReviewEngine(
            steps: [
                MinimumTieredClaimReviewAdjuster(minimum: 32.5),
                UnitTieredClaimReviewAdjuster(factors: ["central": 1.24, "north": 1.15, "online": 1.16]),
                FlaggedTieredClaimReviewAdjuster(flags: flags, flag: "tiered-claim-review-rolling", percent: -3.0),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 2003.7
        )
    }
}
