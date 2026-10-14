import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the rolling float pool estimate calculation.
    protocol RollingFloatPoolEstimateAdjuster {
        func describe() -> String
        func adjust(_ item: RollingFloatPoolEstimate, value: Double) -> Double
    }

    final class TieredRollingFloatPoolEstimateAdjuster: RollingFloatPoolEstimateAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingFloatPoolEstimate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RollingFloatPoolEstimateStartsAtOffsetAdjuster: RollingFloatPoolEstimateAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: RollingFloatPoolEstimate, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    final class RoundingRollingFloatPoolEstimateAdjuster: RollingFloatPoolEstimateAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingFloatPoolEstimate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapRollingFloatPoolEstimateAdjuster: RollingFloatPoolEstimateAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingFloatPoolEstimate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the rolling float pool estimate steps in order and keeps a trace of each.
    final class RollingFloatPoolEstimateEngine {
        var steps: [any RollingFloatPoolEstimateAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingFloatPoolEstimateAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RollingFloatPoolEstimate) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingFloatPoolEstimateAdjuster = steps[index]
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

        func evaluateAll(_ items: [RollingFloatPoolEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRollingFloatPoolEstimateEngine() -> RollingFloatPoolEstimateEngine {
        return RollingFloatPoolEstimateEngine(
            steps: [
                TieredRollingFloatPoolEstimateAdjuster(
                    bounds: [1106.0, 5231.0, 6911.0, 9693.0],
                    rates: [0.85, 1.02, 0.85, 1.2]
                ),
                RollingFloatPoolEstimateStartsAtOffsetAdjuster(weight: 0.9),
                RoundingRollingFloatPoolEstimateAdjuster(step: 1.0),
                CapRollingFloatPoolEstimateAdjuster(cap: 12980.0),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 38627.7
        )
    }
}
