import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the default shift allocation calculation.
    protocol DefaultShiftAllocationModifier {
        func describe() -> String
        func adjust(_ item: DefaultShiftAllocation, value: Double) -> Double
    }

    final class RoundingDefaultShiftAllocationAdjuster: DefaultShiftAllocationModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultShiftAllocation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class DefaultShiftAllocationPriorityOffsetAdjuster: DefaultShiftAllocationModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus priority times \(weight)"
        }

        func adjust(_ item: DefaultShiftAllocation, value: Double) -> Double {
            return value + Double(item.priority) * weight
        }
    }

    final class PercentDefaultShiftAllocationAdjuster: DefaultShiftAllocationModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultShiftAllocation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameDefaultShiftAllocationAdjuster: DefaultShiftAllocationModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: DefaultShiftAllocation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumDefaultShiftAllocationAdjuster: DefaultShiftAllocationModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultShiftAllocation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapDefaultShiftAllocationAdjuster: DefaultShiftAllocationModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultShiftAllocation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the default shift allocation steps in order and keeps a trace of each.
    final class DefaultShiftAllocationEngine {
        var steps: [any DefaultShiftAllocationModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultShiftAllocationModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DefaultShiftAllocation) -> Double {
            var current = item.adjustedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultShiftAllocationModifier = steps[index]
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

        func evaluateAll(_ items: [DefaultShiftAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDefaultShiftAllocationEngine() -> DefaultShiftAllocationEngine {
        return DefaultShiftAllocationEngine(
            steps: [
                RoundingDefaultShiftAllocationAdjuster(step: 0.5),
                DefaultShiftAllocationPriorityOffsetAdjuster(weight: 0.63),
                PercentDefaultShiftAllocationAdjuster(percent: 15.7),
                NameDefaultShiftAllocationAdjuster(factors: ["west": 1.17, "central": 0.99]),
                MinimumDefaultShiftAllocationAdjuster(minimum: 43.6),
                CapDefaultShiftAllocationAdjuster(cap: 38188.0),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 68171.1
        )
    }
}
