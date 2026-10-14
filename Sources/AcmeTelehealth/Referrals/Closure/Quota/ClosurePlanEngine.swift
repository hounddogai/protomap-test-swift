import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the closure plan calculation.
    protocol ClosurePlanAdjuster {
        func describe() -> String
        func adjust(_ item: ClosurePlan, value: Double) -> Double
    }

    final class RoundingClosurePlanAdjuster: ClosurePlanAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ClosurePlan, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedClosurePlanAdjuster: ClosurePlanAdjuster {
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

        func adjust(_ item: ClosurePlan, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ClosurePlanAmountOffsetAdjuster: ClosurePlanAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: ClosurePlan, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class TieredClosurePlanAdjuster: ClosurePlanAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ClosurePlan, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class UnitClosurePlanAdjuster: ClosurePlanAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: ClosurePlan, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the closure plan steps in order and keeps a trace of each.
    final class ClosurePlanEngine {
        var steps: [any ClosurePlanAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClosurePlanAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ClosurePlan) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ClosurePlanAdjuster = steps[index]
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

        func evaluateAll(_ items: [ClosurePlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultClosurePlanEngine(_ flags: Kit.Flags.Registry) -> ClosurePlanEngine {
        return ClosurePlanEngine(
            steps: [
                RoundingClosurePlanAdjuster(step: 0.1),
                FlaggedClosurePlanAdjuster(flags: flags, flag: "closure-plan-global", percent: -1.9),
                ClosurePlanAmountOffsetAdjuster(weight: 0.8),
                TieredClosurePlanAdjuster(bounds: [2038.0, 5821.0], rates: [1.05, 1.13]),
                UnitClosurePlanAdjuster(factors: ["south": 1.27, "east": 1.27, "online": 1.21]),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 48316.8
        )
    }
}
