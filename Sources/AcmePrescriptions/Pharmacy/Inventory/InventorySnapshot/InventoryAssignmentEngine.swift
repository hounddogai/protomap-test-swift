import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the inventory assignment calculation.
    protocol InventoryAssignmentModifier {
        func describe() -> String
        func adjust(_ item: InventoryAssignment, value: Double) -> Double
    }

    final class RoundingInventoryAssignmentAdjuster: InventoryAssignmentModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: InventoryAssignment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class NameInventoryAssignmentAdjuster: InventoryAssignmentModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: InventoryAssignment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapInventoryAssignmentAdjuster: InventoryAssignmentModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: InventoryAssignment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the inventory assignment steps in order and keeps a trace of each.
    final class InventoryAssignmentEngine {
        var steps: [any InventoryAssignmentModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InventoryAssignmentModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: InventoryAssignment) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any InventoryAssignmentModifier = steps[index]
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

        func evaluateAll(_ items: [InventoryAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultInventoryAssignmentEngine() -> InventoryAssignmentEngine {
        return InventoryAssignmentEngine(
            steps: [
                RoundingInventoryAssignmentAdjuster(step: 5.0),
                NameInventoryAssignmentAdjuster(factors: ["online": 0.87, "retail": 1.01]),
                CapInventoryAssignmentAdjuster(cap: 35310.0),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 3617.4
        )
    }
}
