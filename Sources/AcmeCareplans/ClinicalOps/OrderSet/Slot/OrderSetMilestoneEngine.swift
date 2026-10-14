import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the order set milestone calculation.
    protocol OrderSetMilestoneAdjuster {
        func describe() -> String
        func adjust(_ item: OrderSetMilestone, value: Double) -> Double
    }

    final class RoundingOrderSetMilestoneAdjuster: OrderSetMilestoneAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: OrderSetMilestone, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentOrderSetMilestoneAdjuster: OrderSetMilestoneAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: OrderSetMilestone, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class OrderSetMilestoneLimitOffsetAdjuster: OrderSetMilestoneAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus limit times \(weight)"
        }

        func adjust(_ item: OrderSetMilestone, value: Double) -> Double {
            return value + Double(item.limit) * weight
        }
    }

    final class MinimumOrderSetMilestoneAdjuster: OrderSetMilestoneAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: OrderSetMilestone, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LabelOrderSetMilestoneAdjuster: OrderSetMilestoneAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: OrderSetMilestone, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredOrderSetMilestoneAdjuster: OrderSetMilestoneAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: OrderSetMilestone, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the order set milestone steps in order and keeps a trace of each.
    final class OrderSetMilestoneEngine {
        var steps: [any OrderSetMilestoneAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OrderSetMilestoneAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: OrderSetMilestone) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any OrderSetMilestoneAdjuster = steps[index]
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

        func evaluateAll(_ items: [OrderSetMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultOrderSetMilestoneEngine() -> OrderSetMilestoneEngine {
        return OrderSetMilestoneEngine(
            steps: [
                RoundingOrderSetMilestoneAdjuster(step: 0.05),
                PercentOrderSetMilestoneAdjuster(percent: 12.0),
                OrderSetMilestoneLimitOffsetAdjuster(weight: 1.3),
                MinimumOrderSetMilestoneAdjuster(minimum: 48.2),
                LabelOrderSetMilestoneAdjuster(factors: ["north": 0.75]),
                TieredOrderSetMilestoneAdjuster(bounds: [730.0, 3504.0], rates: [0.87, 1.08]),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 34889.0
        )
    }
}
