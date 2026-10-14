import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the closure rule calculation.
    protocol ClosureRuleAdjuster {
        func describe() -> String
        func adjust(_ item: ClosureRule, value: Double) -> Double
    }

    final class FlaggedClosureRuleAdjuster: ClosureRuleAdjuster {
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

        func adjust(_ item: ClosureRule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentClosureRuleAdjuster: ClosureRuleAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ClosureRule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumClosureRuleAdjuster: ClosureRuleAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ClosureRule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredClosureRuleAdjuster: ClosureRuleAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ClosureRule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapClosureRuleAdjuster: ClosureRuleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ClosureRule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the closure rule steps in order and keeps a trace of each.
    final class ClosureRuleEngine {
        var steps: [any ClosureRuleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClosureRuleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ClosureRule) -> Double {
            var current = item.netTotal()
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

        func evaluateAll(_ items: [ClosureRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultClosureRuleEngine(_ flags: Kit.Flags.Registry) -> ClosureRuleEngine {
        return ClosureRuleEngine(
            steps: [
                FlaggedClosureRuleAdjuster(flags: flags, flag: "closure-rule-default", percent: 2.0),
                PercentClosureRuleAdjuster(percent: 8.9),
                MinimumClosureRuleAdjuster(minimum: 21.9),
                TieredClosureRuleAdjuster(bounds: [181.0, 4058.0], rates: [1.06, 0.88]),
                CapClosureRuleAdjuster(cap: 32611.0),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 34435.1
        )
    }
}
