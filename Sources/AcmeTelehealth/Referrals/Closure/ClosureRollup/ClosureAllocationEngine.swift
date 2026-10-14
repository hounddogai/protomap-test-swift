import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the closure allocation calculation.
    protocol ClosureAllocationStep {
        func describe() -> String
        func adjust(_ item: ClosureAllocation, value: Double) -> Double
    }

    final class RoundingClosureAllocationAdjuster: ClosureAllocationStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ClosureAllocation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumClosureAllocationAdjuster: ClosureAllocationStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ClosureAllocation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapClosureAllocationAdjuster: ClosureAllocationStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ClosureAllocation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the closure allocation steps in order and keeps a trace of each.
    final class ClosureAllocationEngine {
        var steps: [any ClosureAllocationStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClosureAllocationStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ClosureAllocation) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ClosureAllocationStep = steps[index]
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

        func evaluateAll(_ items: [ClosureAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultClosureAllocationEngine() -> ClosureAllocationEngine {
        return ClosureAllocationEngine(
            steps: [
                RoundingClosureAllocationAdjuster(step: 5.0),
                MinimumClosureAllocationAdjuster(minimum: 0.5),
                CapClosureAllocationAdjuster(cap: 36636.0),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 34055.7
        )
    }
}
