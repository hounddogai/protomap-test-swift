import AcmePlatform
import Foundation

extension Labs {
    /// One step of the rolling result cycle calculation.
    protocol RollingResultCycleStep {
        func describe() -> String
        func adjust(_ item: RollingResultCycle, value: Double) -> Double
    }

    final class MinimumRollingResultCycleAdjuster: RollingResultCycleStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingResultCycle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class WardRollingResultCycleAdjuster: RollingResultCycleStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: RollingResultCycle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredRollingResultCycleAdjuster: RollingResultCycleStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingResultCycle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the rolling result cycle steps in order and keeps a trace of each.
    final class RollingResultCycleEngine {
        var steps: [any RollingResultCycleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingResultCycleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RollingResultCycle) -> Double {
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

        func evaluateAll(_ items: [RollingResultCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRollingResultCycleEngine() -> RollingResultCycleEngine {
        return RollingResultCycleEngine(
            steps: [
                MinimumRollingResultCycleAdjuster(minimum: 36.8),
                WardRollingResultCycleAdjuster(factors: ["south": 1.37]),
                TieredRollingResultCycleAdjuster(
                    bounds: [3491.0, 4096.0, 6523.0, 9902.0],
                    rates: [1.12, 1.05, 1.18, 0.96]
                ),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 60585.2
        )
    }
}
