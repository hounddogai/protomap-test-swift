import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the global dispense rule calculation.
    protocol GlobalDispenseRuleAdjuster {
        func describe() -> String
        func adjust(_ item: GlobalDispenseRule, value: Double) -> Double
    }

    final class TieredGlobalDispenseRuleAdjuster: GlobalDispenseRuleAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalDispenseRule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class GlobalDispenseRuleCreatedAtOffsetAdjuster: GlobalDispenseRuleAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: GlobalDispenseRule, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    final class RoundingGlobalDispenseRuleAdjuster: GlobalDispenseRuleAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalDispenseRule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumGlobalDispenseRuleAdjuster: GlobalDispenseRuleAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalDispenseRule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedGlobalDispenseRuleAdjuster: GlobalDispenseRuleAdjuster {
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

        func adjust(_ item: GlobalDispenseRule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentGlobalDispenseRuleAdjuster: GlobalDispenseRuleAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalDispenseRule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the global dispense rule steps in order and keeps a trace of each.
    final class GlobalDispenseRuleEngine {
        var steps: [any GlobalDispenseRuleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalDispenseRuleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: GlobalDispenseRule) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalDispenseRuleAdjuster = steps[index]
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

        func evaluateAll(_ items: [GlobalDispenseRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultGlobalDispenseRuleEngine(_ flags: Kit.Flags.Registry) -> GlobalDispenseRuleEngine {
        return GlobalDispenseRuleEngine(
            steps: [
                TieredGlobalDispenseRuleAdjuster(bounds: [541.0, 4703.0], rates: [1.01, 1.01]),
                GlobalDispenseRuleCreatedAtOffsetAdjuster(weight: 0.11),
                RoundingGlobalDispenseRuleAdjuster(step: 0.1),
                MinimumGlobalDispenseRuleAdjuster(minimum: 7.3),
                FlaggedGlobalDispenseRuleAdjuster(flags: flags, flag: "global-dispense-rule-adaptive", percent: -7.9),
                PercentGlobalDispenseRuleAdjuster(percent: -15.7),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 63332.2
        )
    }
}
