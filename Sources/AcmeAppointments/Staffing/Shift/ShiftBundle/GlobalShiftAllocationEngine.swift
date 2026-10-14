import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the global shift allocation calculation.
    protocol GlobalShiftAllocationModifier {
        func describe() -> String
        func adjust(_ item: GlobalShiftAllocation, value: Double) -> Double
    }

    final class CapGlobalShiftAllocationAdjuster: GlobalShiftAllocationModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalShiftAllocation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class GlobalShiftAllocationBudgetOffsetAdjuster: GlobalShiftAllocationModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: GlobalShiftAllocation, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    final class CategoryGlobalShiftAllocationAdjuster: GlobalShiftAllocationModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: GlobalShiftAllocation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingGlobalShiftAllocationAdjuster: GlobalShiftAllocationModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalShiftAllocation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumGlobalShiftAllocationAdjuster: GlobalShiftAllocationModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalShiftAllocation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the global shift allocation steps in order and keeps a trace of each.
    final class GlobalShiftAllocationEngine {
        var steps: [any GlobalShiftAllocationModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalShiftAllocationModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: GlobalShiftAllocation) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalShiftAllocationModifier = steps[index]
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

        func evaluateAll(_ items: [GlobalShiftAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultGlobalShiftAllocationEngine() -> GlobalShiftAllocationEngine {
        return GlobalShiftAllocationEngine(
            steps: [
                CapGlobalShiftAllocationAdjuster(cap: 37481.0),
                GlobalShiftAllocationBudgetOffsetAdjuster(weight: 0.28),
                CategoryGlobalShiftAllocationAdjuster(factors: ["west": 0.87]),
                RoundingGlobalShiftAllocationAdjuster(step: 0.25),
                MinimumGlobalShiftAllocationAdjuster(minimum: 29.6),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 19071.9
        )
    }
}
