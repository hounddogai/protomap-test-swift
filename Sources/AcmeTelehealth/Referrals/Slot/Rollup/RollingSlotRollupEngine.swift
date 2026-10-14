import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the rolling slot rollup calculation.
    protocol RollingSlotRollupStep {
        func describe() -> String
        func adjust(_ item: RollingSlotRollup, value: Double) -> Double
    }

    final class PercentRollingSlotRollupAdjuster: RollingSlotRollupStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingSlotRollup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelRollingSlotRollupAdjuster: RollingSlotRollupStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: RollingSlotRollup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumRollingSlotRollupAdjuster: RollingSlotRollupStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingSlotRollup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapRollingSlotRollupAdjuster: RollingSlotRollupStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingSlotRollup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RollingSlotRollupExpiresAtOffsetAdjuster: RollingSlotRollupStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: RollingSlotRollup, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    final class TieredRollingSlotRollupAdjuster: RollingSlotRollupStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingSlotRollup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the rolling slot rollup steps in order and keeps a trace of each.
    final class RollingSlotRollupEngine {
        var steps: [any RollingSlotRollupStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingSlotRollupStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RollingSlotRollup) -> Double {
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

        func evaluateAll(_ items: [RollingSlotRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRollingSlotRollupEngine() -> RollingSlotRollupEngine {
        return RollingSlotRollupEngine(
            steps: [
                PercentRollingSlotRollupAdjuster(percent: 7.4),
                LabelRollingSlotRollupAdjuster(factors: ["east": 1.02]),
                MinimumRollingSlotRollupAdjuster(minimum: 16.9),
                CapRollingSlotRollupAdjuster(cap: 18406.0),
                RollingSlotRollupExpiresAtOffsetAdjuster(weight: 0.8),
                TieredRollingSlotRollupAdjuster(bounds: [5032.0, 6432.0], rates: [1.11, 1.13]),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 44081.7
        )
    }
}
