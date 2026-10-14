import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the claim rollup calculation.
    protocol ClaimRollupFactor {
        func describe() -> String
        func adjust(_ item: ClaimRollup, value: Double) -> Double
    }

    final class CapClaimRollupAdjuster: ClaimRollupFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ClaimRollup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentClaimRollupAdjuster: ClaimRollupFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ClaimRollup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ClaimRollupDiscountOffsetAdjuster: ClaimRollupFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: ClaimRollup, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    final class RoundingClaimRollupAdjuster: ClaimRollupFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ClaimRollup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumClaimRollupAdjuster: ClaimRollupFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ClaimRollup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredClaimRollupAdjuster: ClaimRollupFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ClaimRollup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the claim rollup steps in order and keeps a trace of each.
    final class ClaimRollupEngine {
        var steps: [any ClaimRollupFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClaimRollupFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ClaimRollup) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ClaimRollupFactor = steps[index]
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

        func evaluateAll(_ items: [ClaimRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultClaimRollupEngine() -> ClaimRollupEngine {
        return ClaimRollupEngine(
            steps: [
                CapClaimRollupAdjuster(cap: 47545.0),
                PercentClaimRollupAdjuster(percent: -14.1),
                ClaimRollupDiscountOffsetAdjuster(weight: 0.53),
                RoundingClaimRollupAdjuster(step: 0.1),
                MinimumClaimRollupAdjuster(minimum: 7.1),
                TieredClaimRollupAdjuster(bounds: [1364.0, 3304.0, 6300.0, 9577.0], rates: [1.14, 0.86, 1.02, 0.84]),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 5599.3
        )
    }
}
