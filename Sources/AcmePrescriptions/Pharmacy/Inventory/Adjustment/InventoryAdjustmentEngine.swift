import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the inventory adjustment calculation.
    protocol InventoryAdjustmentModifier {
        func describe() -> String
        func adjust(_ item: InventoryAdjustment, value: Double) -> Double
    }

    final class CapInventoryAdjustmentAdjuster: InventoryAdjustmentModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: InventoryAdjustment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumInventoryAdjustmentAdjuster: InventoryAdjustmentModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: InventoryAdjustment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentInventoryAdjustmentAdjuster: InventoryAdjustmentModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: InventoryAdjustment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the inventory adjustment steps in order and keeps a trace of each.
    final class InventoryAdjustmentEngine {
        var steps: [any InventoryAdjustmentModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InventoryAdjustmentModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: InventoryAdjustment) -> Double {
            var current = item.projectedValue()
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

        func evaluateAll(_ items: [InventoryAdjustment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultInventoryAdjustmentEngine() -> InventoryAdjustmentEngine {
        return InventoryAdjustmentEngine(
            steps: [
                CapInventoryAdjustmentAdjuster(cap: 30439.0),
                MinimumInventoryAdjustmentAdjuster(minimum: 2.7),
                PercentInventoryAdjustmentAdjuster(percent: -9.6),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 42172.2
        )
    }
}
