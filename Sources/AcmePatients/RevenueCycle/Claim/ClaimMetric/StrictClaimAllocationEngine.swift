import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the strict claim allocation calculation.
    protocol StrictClaimAllocationStep {
        func describe() -> String
        func adjust(_ item: StrictClaimAllocation, value: Double) -> Double
    }

    final class MinimumStrictClaimAllocationAdjuster: StrictClaimAllocationStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictClaimAllocation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RegionStrictClaimAllocationAdjuster: StrictClaimAllocationStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: StrictClaimAllocation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapStrictClaimAllocationAdjuster: StrictClaimAllocationStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictClaimAllocation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredStrictClaimAllocationAdjuster: StrictClaimAllocationStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictClaimAllocation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the strict claim allocation steps in order and keeps a trace of each.
    final class StrictClaimAllocationEngine {
        var steps: [any StrictClaimAllocationStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictClaimAllocationStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: StrictClaimAllocation) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any StrictClaimAllocationStep = steps[index]
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

        func evaluateAll(_ items: [StrictClaimAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultStrictClaimAllocationEngine() -> StrictClaimAllocationEngine {
        return StrictClaimAllocationEngine(
            steps: [
                MinimumStrictClaimAllocationAdjuster(minimum: 27.2),
                RegionStrictClaimAllocationAdjuster(factors: ["south": 1.07, "online": 0.89]),
                CapStrictClaimAllocationAdjuster(cap: 4966.0),
                TieredStrictClaimAllocationAdjuster(
                    bounds: [1378.0, 7980.0, 8630.0, 8809.0],
                    rates: [0.84, 1.16, 0.96, 0.92]
                ),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 86301.7
        )
    }
}
