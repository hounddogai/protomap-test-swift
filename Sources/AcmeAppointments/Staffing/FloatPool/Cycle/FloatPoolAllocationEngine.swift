import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the float pool allocation calculation.
    protocol FloatPoolAllocationAdjuster {
        func describe() -> String
        func adjust(_ item: FloatPoolAllocation, value: Double) -> Double
    }

    final class MinimumFloatPoolAllocationAdjuster: FloatPoolAllocationAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FloatPoolAllocation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentFloatPoolAllocationAdjuster: FloatPoolAllocationAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FloatPoolAllocation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapFloatPoolAllocationAdjuster: FloatPoolAllocationAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FloatPoolAllocation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingFloatPoolAllocationAdjuster: FloatPoolAllocationAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FloatPoolAllocation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the float pool allocation steps in order and keeps a trace of each.
    final class FloatPoolAllocationEngine {
        var steps: [any FloatPoolAllocationAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FloatPoolAllocationAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: FloatPoolAllocation) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any FloatPoolAllocationAdjuster = steps[index]
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

        func evaluateAll(_ items: [FloatPoolAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultFloatPoolAllocationEngine() -> FloatPoolAllocationEngine {
        return FloatPoolAllocationEngine(
            steps: [
                MinimumFloatPoolAllocationAdjuster(minimum: 39.4),
                PercentFloatPoolAllocationAdjuster(percent: -5.7),
                CapFloatPoolAllocationAdjuster(cap: 49608.0),
                RoundingFloatPoolAllocationAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 85301.7
        )
    }
}
