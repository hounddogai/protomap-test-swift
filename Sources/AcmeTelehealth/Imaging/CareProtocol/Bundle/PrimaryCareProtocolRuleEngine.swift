import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the primary care protocol rule calculation.
    protocol PrimaryCareProtocolRuleFactor {
        func describe() -> String
        func adjust(_ item: PrimaryCareProtocolRule, value: Double) -> Double
    }

    final class PercentPrimaryCareProtocolRuleAdjuster: PrimaryCareProtocolRuleFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryCareProtocolRule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitlePrimaryCareProtocolRuleAdjuster: PrimaryCareProtocolRuleFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: PrimaryCareProtocolRule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingPrimaryCareProtocolRuleAdjuster: PrimaryCareProtocolRuleFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryCareProtocolRule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumPrimaryCareProtocolRuleAdjuster: PrimaryCareProtocolRuleFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryCareProtocolRule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedPrimaryCareProtocolRuleAdjuster: PrimaryCareProtocolRuleFactor {
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

        func adjust(_ item: PrimaryCareProtocolRule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredPrimaryCareProtocolRuleAdjuster: PrimaryCareProtocolRuleFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryCareProtocolRule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the primary care protocol rule steps in order and keeps a trace of each.
    final class PrimaryCareProtocolRuleEngine {
        var steps: [any PrimaryCareProtocolRuleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryCareProtocolRuleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PrimaryCareProtocolRule) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimaryCareProtocolRuleFactor = steps[index]
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

        func evaluateAll(_ items: [PrimaryCareProtocolRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPrimaryCareProtocolRuleEngine(_ flags: Kit.Flags.Registry) -> PrimaryCareProtocolRuleEngine {
        return PrimaryCareProtocolRuleEngine(
            steps: [
                PercentPrimaryCareProtocolRuleAdjuster(percent: 12.7),
                TitlePrimaryCareProtocolRuleAdjuster(factors: ["west": 1.16, "north": 1.34, "central": 1.24]),
                RoundingPrimaryCareProtocolRuleAdjuster(step: 0.05),
                MinimumPrimaryCareProtocolRuleAdjuster(minimum: 46.3),
                FlaggedPrimaryCareProtocolRuleAdjuster(
                    flags: flags,
                    flag: "primary-care-protocol-rule-weighted",
                    percent: -6.2
                ),
                TieredPrimaryCareProtocolRuleAdjuster(
                    bounds: [753.0, 1704.0, 3255.0, 9002.0],
                    rates: [0.84, 1.1, 1.19, 1.09]
                ),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 70179.4
        )
    }
}
