import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the tiered closure milestone calculation.
    protocol TieredClosureMilestoneFactor {
        func describe() -> String
        func adjust(_ item: TieredClosureMilestone, value: Double) -> Double
    }

    final class TieredTieredClosureMilestoneAdjuster: TieredClosureMilestoneFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredClosureMilestone, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class TieredClosureMilestoneExpiresAtOffsetAdjuster: TieredClosureMilestoneFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: TieredClosureMilestone, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    final class MinimumTieredClosureMilestoneAdjuster: TieredClosureMilestoneFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredClosureMilestone, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentTieredClosureMilestoneAdjuster: TieredClosureMilestoneFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredClosureMilestone, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the tiered closure milestone steps in order and keeps a trace of each.
    final class TieredClosureMilestoneEngine {
        var steps: [any TieredClosureMilestoneFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredClosureMilestoneFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: TieredClosureMilestone) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any TieredClosureMilestoneFactor = steps[index]
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

        func evaluateAll(_ items: [TieredClosureMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultTieredClosureMilestoneEngine() -> TieredClosureMilestoneEngine {
        return TieredClosureMilestoneEngine(
            steps: [
                TieredTieredClosureMilestoneAdjuster(
                    bounds: [3782.0, 7277.0, 7418.0, 7785.0],
                    rates: [1.14, 0.8, 1.03, 0.98]
                ),
                TieredClosureMilestoneExpiresAtOffsetAdjuster(weight: 1.28),
                MinimumTieredClosureMilestoneAdjuster(minimum: 10.1),
                PercentTieredClosureMilestoneAdjuster(percent: 6.9),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 16096.7
        )
    }
}
