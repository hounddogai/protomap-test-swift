import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the strict read allocation calculation.
    protocol StrictReadAllocationFactor {
        func describe() -> String
        func adjust(_ item: StrictReadAllocation, value: Double) -> Double
    }

    final class FacilityStrictReadAllocationAdjuster: StrictReadAllocationFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: StrictReadAllocation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumStrictReadAllocationAdjuster: StrictReadAllocationFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictReadAllocation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapStrictReadAllocationAdjuster: StrictReadAllocationFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictReadAllocation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the strict read allocation steps in order and keeps a trace of each.
    final class StrictReadAllocationEngine {
        var steps: [any StrictReadAllocationFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictReadAllocationFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: StrictReadAllocation) -> Double {
            var current = item.netValue()
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

        func evaluateAll(_ items: [StrictReadAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultStrictReadAllocationEngine() -> StrictReadAllocationEngine {
        return StrictReadAllocationEngine(
            steps: [
                FacilityStrictReadAllocationAdjuster(factors: ["central": 1.29]),
                MinimumStrictReadAllocationAdjuster(minimum: 0.2),
                CapStrictReadAllocationAdjuster(cap: 41592.0),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 7850.0
        )
    }
}
