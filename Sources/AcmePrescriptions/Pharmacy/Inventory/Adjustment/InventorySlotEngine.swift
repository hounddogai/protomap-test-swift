import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the inventory slot calculation.
    protocol InventorySlotAdjuster {
        func describe() -> String
        func adjust(_ item: InventorySlot, value: Double) -> Double
    }

    final class CapInventorySlotAdjuster: InventorySlotAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: InventorySlot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumInventorySlotAdjuster: InventorySlotAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: InventorySlot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredInventorySlotAdjuster: InventorySlotAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: InventorySlot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the inventory slot steps in order and keeps a trace of each.
    final class InventorySlotEngine {
        var steps: [any InventorySlotAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InventorySlotAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: InventorySlot) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [InventorySlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultInventorySlotEngine() -> InventorySlotEngine {
        return InventorySlotEngine(
            steps: [
                CapInventorySlotAdjuster(cap: 7272.0),
                MinimumInventorySlotAdjuster(minimum: 3.8),
                TieredInventorySlotAdjuster(bounds: [1705.0, 2253.0, 3354.0, 5961.0], rates: [0.89, 0.99, 0.9, 1.18]),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 14301.7
        )
    }
}
