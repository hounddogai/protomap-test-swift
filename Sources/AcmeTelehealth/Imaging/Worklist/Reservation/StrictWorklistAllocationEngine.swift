import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the strict worklist allocation calculation.
    protocol StrictWorklistAllocationModifier {
        func describe() -> String
        func adjust(_ item: StrictWorklistAllocation, value: Double) -> Double
    }

    final class CapStrictWorklistAllocationAdjuster: StrictWorklistAllocationModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictWorklistAllocation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentStrictWorklistAllocationAdjuster: StrictWorklistAllocationModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictWorklistAllocation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumStrictWorklistAllocationAdjuster: StrictWorklistAllocationModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictWorklistAllocation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class NameStrictWorklistAllocationAdjuster: StrictWorklistAllocationModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: StrictWorklistAllocation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingStrictWorklistAllocationAdjuster: StrictWorklistAllocationModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictWorklistAllocation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the strict worklist allocation steps in order and keeps a trace of each.
    final class StrictWorklistAllocationEngine {
        var steps: [any StrictWorklistAllocationModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictWorklistAllocationModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: StrictWorklistAllocation) -> Double {
            var current = item.adjustedLoad()
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

        func evaluateAll(_ items: [StrictWorklistAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultStrictWorklistAllocationEngine() -> StrictWorklistAllocationEngine {
        return StrictWorklistAllocationEngine(
            steps: [
                CapStrictWorklistAllocationAdjuster(cap: 3000.0),
                PercentStrictWorklistAllocationAdjuster(percent: 14.2),
                MinimumStrictWorklistAllocationAdjuster(minimum: 31.2),
                NameStrictWorklistAllocationAdjuster(factors: ["east": 1.27, "online": 0.74]),
                RoundingStrictWorklistAllocationAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 38865.5
        )
    }
}
