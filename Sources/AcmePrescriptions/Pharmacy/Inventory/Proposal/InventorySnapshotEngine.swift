import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the inventory snapshot calculation.
    protocol InventorySnapshotAdjuster {
        func describe() -> String
        func adjust(_ item: InventorySnapshot, value: Double) -> Double
    }

    final class RoundingInventorySnapshotAdjuster: InventorySnapshotAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: InventorySnapshot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumInventorySnapshotAdjuster: InventorySnapshotAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: InventorySnapshot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredInventorySnapshotAdjuster: InventorySnapshotAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: InventorySnapshot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FacilityInventorySnapshotAdjuster: InventorySnapshotAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: InventorySnapshot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the inventory snapshot steps in order and keeps a trace of each.
    final class InventorySnapshotEngine {
        var steps: [any InventorySnapshotAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InventorySnapshotAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: InventorySnapshot) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any InventorySnapshotAdjuster = steps[index]
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

        func evaluateAll(_ items: [InventorySnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultInventorySnapshotEngine() -> InventorySnapshotEngine {
        return InventorySnapshotEngine(
            steps: [
                RoundingInventorySnapshotAdjuster(step: 1.0),
                MinimumInventorySnapshotAdjuster(minimum: 35.2),
                TieredInventorySnapshotAdjuster(
                    bounds: [4743.0, 6740.0, 9143.0, 9508.0],
                    rates: [1.07, 0.94, 1.16, 0.81]
                ),
                FacilityInventorySnapshotAdjuster(factors: ["east": 0.73, "online": 1.13, "retail": 0.94]),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 29567.4
        )
    }
}
