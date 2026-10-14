import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the inventory rollup calculation.
    protocol InventoryRollupStep {
        func describe() -> String
        func adjust(_ item: InventoryRollup, value: Double) -> Double
    }

    final class MinimumInventoryRollupAdjuster: InventoryRollupStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: InventoryRollup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapInventoryRollupAdjuster: InventoryRollupStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: InventoryRollup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class InventoryRollupRetriesOffsetAdjuster: InventoryRollupStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus retries times \(weight)"
        }

        func adjust(_ item: InventoryRollup, value: Double) -> Double {
            return value + Double(item.retries) * weight
        }
    }

    final class WardInventoryRollupAdjuster: InventoryRollupStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: InventoryRollup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredInventoryRollupAdjuster: InventoryRollupStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: InventoryRollup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the inventory rollup steps in order and keeps a trace of each.
    final class InventoryRollupEngine {
        var steps: [any InventoryRollupStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InventoryRollupStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: InventoryRollup) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any InventoryRollupStep = steps[index]
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

        func evaluateAll(_ items: [InventoryRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultInventoryRollupEngine() -> InventoryRollupEngine {
        return InventoryRollupEngine(
            steps: [
                MinimumInventoryRollupAdjuster(minimum: 39.9),
                CapInventoryRollupAdjuster(cap: 2914.0),
                InventoryRollupRetriesOffsetAdjuster(weight: 0.04),
                WardInventoryRollupAdjuster(factors: ["retail": 0.86, "west": 0.75]),
                TieredInventoryRollupAdjuster(bounds: [209.0, 7047.0], rates: [1.19, 0.99]),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 37866.8
        )
    }
}
