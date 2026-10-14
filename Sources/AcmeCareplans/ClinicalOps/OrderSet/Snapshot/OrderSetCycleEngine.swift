import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the order set cycle calculation.
    protocol OrderSetCycleAdjuster {
        func describe() -> String
        func adjust(_ item: OrderSetCycle, value: Double) -> Double
    }

    final class OrderSetCycleExpiresAtOffsetAdjuster: OrderSetCycleAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: OrderSetCycle, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    final class RoundingOrderSetCycleAdjuster: OrderSetCycleAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: OrderSetCycle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapOrderSetCycleAdjuster: OrderSetCycleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: OrderSetCycle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RegionOrderSetCycleAdjuster: OrderSetCycleAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: OrderSetCycle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredOrderSetCycleAdjuster: OrderSetCycleAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: OrderSetCycle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the order set cycle steps in order and keeps a trace of each.
    final class OrderSetCycleEngine {
        var steps: [any OrderSetCycleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OrderSetCycleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: OrderSetCycle) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any OrderSetCycleAdjuster = steps[index]
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

        func evaluateAll(_ items: [OrderSetCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultOrderSetCycleEngine() -> OrderSetCycleEngine {
        return OrderSetCycleEngine(
            steps: [
                OrderSetCycleExpiresAtOffsetAdjuster(weight: 0.65),
                RoundingOrderSetCycleAdjuster(step: 0.25),
                CapOrderSetCycleAdjuster(cap: 1960.0),
                RegionOrderSetCycleAdjuster(factors: ["west": 1.21]),
                TieredOrderSetCycleAdjuster(bounds: [3941.0, 7346.0], rates: [1.1, 1.18]),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 72441.7
        )
    }
}
