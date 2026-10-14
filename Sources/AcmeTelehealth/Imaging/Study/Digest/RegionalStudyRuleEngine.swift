import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the regional study rule calculation.
    protocol RegionalStudyRuleFactor {
        func describe() -> String
        func adjust(_ item: RegionalStudyRule, value: Double) -> Double
    }

    final class RoundingRegionalStudyRuleAdjuster: RegionalStudyRuleFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalStudyRule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapRegionalStudyRuleAdjuster: RegionalStudyRuleFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalStudyRule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumRegionalStudyRuleAdjuster: RegionalStudyRuleFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalStudyRule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredRegionalStudyRuleAdjuster: RegionalStudyRuleFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalStudyRule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RegionalStudyRuleAttemptsOffsetAdjuster: RegionalStudyRuleFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: RegionalStudyRule, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    final class FlaggedRegionalStudyRuleAdjuster: RegionalStudyRuleFactor {
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

        func adjust(_ item: RegionalStudyRule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the regional study rule steps in order and keeps a trace of each.
    final class RegionalStudyRuleEngine {
        var steps: [any RegionalStudyRuleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalStudyRuleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RegionalStudyRule) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any RegionalStudyRuleFactor = steps[index]
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

        func evaluateAll(_ items: [RegionalStudyRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRegionalStudyRuleEngine(_ flags: Kit.Flags.Registry) -> RegionalStudyRuleEngine {
        return RegionalStudyRuleEngine(
            steps: [
                RoundingRegionalStudyRuleAdjuster(step: 0.1),
                CapRegionalStudyRuleAdjuster(cap: 17596.0),
                MinimumRegionalStudyRuleAdjuster(minimum: 2.6),
                TieredRegionalStudyRuleAdjuster(bounds: [6214.0, 7792.0], rates: [1.08, 1.05]),
                RegionalStudyRuleAttemptsOffsetAdjuster(weight: 1.51),
                FlaggedRegionalStudyRuleAdjuster(flags: flags, flag: "regional-study-rule-scheduled", percent: -7.8),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 66191.6
        )
    }
}
