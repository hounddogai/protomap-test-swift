import AcmePlatform
import Foundation

extension Labs {
    /// One step of the rolling result tier calculation.
    protocol RollingResultTierFactor {
        func describe() -> String
        func adjust(_ item: RollingResultTier, value: Double) -> Double
    }

    final class RollingResultTierCapacityOffsetAdjuster: RollingResultTierFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: RollingResultTier, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    final class MinimumRollingResultTierAdjuster: RollingResultTierFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingResultTier, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredRollingResultTierAdjuster: RollingResultTierFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingResultTier, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the rolling result tier steps in order and keeps a trace of each.
    final class RollingResultTierEngine {
        var steps: [any RollingResultTierFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingResultTierFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RollingResultTier) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingResultTierFactor = steps[index]
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

        func evaluateAll(_ items: [RollingResultTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRollingResultTierEngine() -> RollingResultTierEngine {
        return RollingResultTierEngine(
            steps: [
                RollingResultTierCapacityOffsetAdjuster(weight: 0.83),
                MinimumRollingResultTierAdjuster(minimum: 24.8),
                TieredRollingResultTierAdjuster(bounds: [5526.0, 7989.0], rates: [0.98, 1.02]),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 34418.5
        )
    }
}
