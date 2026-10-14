import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the tiered float pool plan calculation.
    protocol PoolPlanTieredFloatPoolPlanAdjuster {
        func describe() -> String
        func adjust(_ item: TieredFloatPoolPlan, value: Double) -> Double
    }

    final class RoundingTieredFloatPoolPlanAdjuster: PoolPlanTieredFloatPoolPlanAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredFloatPoolPlan, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedTieredFloatPoolPlanAdjuster: PoolPlanTieredFloatPoolPlanAdjuster {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: TieredFloatPoolPlan, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumTieredFloatPoolPlanAdjuster: PoolPlanTieredFloatPoolPlanAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredFloatPoolPlan, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the tiered float pool plan steps in order and keeps a trace of each.
    final class TieredFloatPoolPlanEngine {
        var steps: [any PoolPlanTieredFloatPoolPlanAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PoolPlanTieredFloatPoolPlanAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: TieredFloatPoolPlan) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any PoolPlanTieredFloatPoolPlanAdjuster = steps[index]
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

        func evaluateAll(_ items: [TieredFloatPoolPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultTieredFloatPoolPlanEngine(_ flags: Kit.Flags.Registry) -> TieredFloatPoolPlanEngine {
        return TieredFloatPoolPlanEngine(
            steps: [
                RoundingTieredFloatPoolPlanAdjuster(step: 5.0),
                FlaggedTieredFloatPoolPlanAdjuster(flags: flags, flag: "tiered-float-pool-plan-manual", percent: 7.1),
                MinimumTieredFloatPoolPlanAdjuster(minimum: 18.2),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 22779.0
        )
    }
}
