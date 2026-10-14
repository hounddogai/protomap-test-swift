import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the follow up adjustment calculation.
    protocol FollowUpAdjustmentAdjuster {
        func describe() -> String
        func adjust(_ item: FollowUpAdjustment, value: Double) -> Double
    }

    final class PercentFollowUpAdjustmentAdjuster: FollowUpAdjustmentAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FollowUpAdjustment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumFollowUpAdjustmentAdjuster: FollowUpAdjustmentAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FollowUpAdjustment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class NameFollowUpAdjustmentAdjuster: FollowUpAdjustmentAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: FollowUpAdjustment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FollowUpAdjustmentScoreOffsetAdjuster: FollowUpAdjustmentAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: FollowUpAdjustment, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class TieredFollowUpAdjustmentAdjuster: FollowUpAdjustmentAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FollowUpAdjustment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the follow up adjustment steps in order and keeps a trace of each.
    final class FollowUpAdjustmentEngine {
        var steps: [any FollowUpAdjustmentAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FollowUpAdjustmentAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: FollowUpAdjustment) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any FollowUpAdjustmentAdjuster = steps[index]
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

        func evaluateAll(_ items: [FollowUpAdjustment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultFollowUpAdjustmentEngine() -> FollowUpAdjustmentEngine {
        return FollowUpAdjustmentEngine(
            steps: [
                PercentFollowUpAdjustmentAdjuster(percent: -18.9),
                MinimumFollowUpAdjustmentAdjuster(minimum: 26.6),
                NameFollowUpAdjustmentAdjuster(factors: ["west": 1.25]),
                FollowUpAdjustmentScoreOffsetAdjuster(weight: 1.43),
                TieredFollowUpAdjustmentAdjuster(bounds: [1431.0, 1892.0, 6463.0], rates: [0.89, 0.93, 1.0]),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 77883.6
        )
    }
}
