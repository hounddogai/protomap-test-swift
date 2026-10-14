import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the claim allocation calculation.
    protocol ClaimAllocationAdjuster {
        func describe() -> String
        func adjust(_ item: ClaimAllocation, value: Double) -> Double
    }

    final class RoundingClaimAllocationAdjuster: ClaimAllocationAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ClaimAllocation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumClaimAllocationAdjuster: ClaimAllocationAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ClaimAllocation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapClaimAllocationAdjuster: ClaimAllocationAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ClaimAllocation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class NameClaimAllocationAdjuster: ClaimAllocationAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: ClaimAllocation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class ClaimAllocationRatioOffsetAdjuster: ClaimAllocationAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: ClaimAllocation, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    final class PercentClaimAllocationAdjuster: ClaimAllocationAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ClaimAllocation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the claim allocation steps in order and keeps a trace of each.
    final class ClaimAllocationEngine {
        var steps: [any ClaimAllocationAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClaimAllocationAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ClaimAllocation) -> Double {
            var current = item.projectedValue()
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

        func evaluateAll(_ items: [ClaimAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultClaimAllocationEngine() -> ClaimAllocationEngine {
        return ClaimAllocationEngine(
            steps: [
                RoundingClaimAllocationAdjuster(step: 0.1),
                MinimumClaimAllocationAdjuster(minimum: 31.7),
                CapClaimAllocationAdjuster(cap: 4555.0),
                NameClaimAllocationAdjuster(factors: ["online": 1.09]),
                ClaimAllocationRatioOffsetAdjuster(weight: 1.61),
                PercentClaimAllocationAdjuster(percent: -6.9),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 54306.1
        )
    }
}
