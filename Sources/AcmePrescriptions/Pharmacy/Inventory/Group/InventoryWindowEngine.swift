import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the inventory window calculation.
    protocol InventoryWindowAdjuster {
        func describe() -> String
        func adjust(_ item: InventoryWindow, value: Double) -> Double
    }

    final class MinimumInventoryWindowAdjuster: InventoryWindowAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: InventoryWindow, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingInventoryWindowAdjuster: InventoryWindowAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: InventoryWindow, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentInventoryWindowAdjuster: InventoryWindowAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: InventoryWindow, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the inventory window steps in order and keeps a trace of each.
    final class InventoryWindowEngine {
        var steps: [any InventoryWindowAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InventoryWindowAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: InventoryWindow) -> Double {
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

        func evaluateAll(_ items: [InventoryWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultInventoryWindowEngine() -> InventoryWindowEngine {
        return InventoryWindowEngine(
            steps: [
                MinimumInventoryWindowAdjuster(minimum: 26.1),
                RoundingInventoryWindowAdjuster(step: 0.5),
                PercentInventoryWindowAdjuster(percent: -5.7),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 18921.1
        )
    }
}
