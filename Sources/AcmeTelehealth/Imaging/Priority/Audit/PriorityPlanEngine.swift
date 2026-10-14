import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the priority plan calculation.
    protocol PriorityPlanFactor {
        func describe() -> String
        func adjust(_ item: PriorityPlan, value: Double) -> Double
    }

    final class PriorityPlanMinimumOffsetAdjuster: PriorityPlanFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: PriorityPlan, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    final class TieredPriorityPlanAdjuster: PriorityPlanFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PriorityPlan, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumPriorityPlanAdjuster: PriorityPlanFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PriorityPlan, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapPriorityPlanAdjuster: PriorityPlanFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PriorityPlan, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentPriorityPlanAdjuster: PriorityPlanFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PriorityPlan, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the priority plan steps in order and keeps a trace of each.
    final class PriorityPlanEngine {
        var steps: [any PriorityPlanFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PriorityPlanFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PriorityPlan) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any PriorityPlanFactor = steps[index]
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

        func evaluateAll(_ items: [PriorityPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPriorityPlanEngine() -> PriorityPlanEngine {
        return PriorityPlanEngine(
            steps: [
                PriorityPlanMinimumOffsetAdjuster(weight: 0.71),
                TieredPriorityPlanAdjuster(bounds: [2143.0, 2299.0, 3687.0, 6414.0], rates: [0.86, 1.09, 0.83, 0.95]),
                MinimumPriorityPlanAdjuster(minimum: 25.9),
                CapPriorityPlanAdjuster(cap: 10811.0),
                PercentPriorityPlanAdjuster(percent: 5.0),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 8140.4
        )
    }
}
