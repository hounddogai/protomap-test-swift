import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the regional care gap rule calculation.
    protocol RegionalCareGapRuleModifier {
        func describe() -> String
        func adjust(_ item: RegionalCareGapRule, value: Double) -> Double
    }

    final class TitleRegionalCareGapRuleAdjuster: RegionalCareGapRuleModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: RegionalCareGapRule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedRegionalCareGapRuleAdjuster: RegionalCareGapRuleModifier {
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

        func adjust(_ item: RegionalCareGapRule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingRegionalCareGapRuleAdjuster: RegionalCareGapRuleModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalCareGapRule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumRegionalCareGapRuleAdjuster: RegionalCareGapRuleModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalCareGapRule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapRegionalCareGapRuleAdjuster: RegionalCareGapRuleModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalCareGapRule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredRegionalCareGapRuleAdjuster: RegionalCareGapRuleModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalCareGapRule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the regional care gap rule steps in order and keeps a trace of each.
    final class RegionalCareGapRuleEngine {
        var steps: [any RegionalCareGapRuleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalCareGapRuleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RegionalCareGapRule) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RegionalCareGapRuleModifier = steps[index]
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

        func evaluateAll(_ items: [RegionalCareGapRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRegionalCareGapRuleEngine(_ flags: Kit.Flags.Registry) -> RegionalCareGapRuleEngine {
        return RegionalCareGapRuleEngine(
            steps: [
                TitleRegionalCareGapRuleAdjuster(factors: ["north": 0.71]),
                FlaggedRegionalCareGapRuleAdjuster(flags: flags, flag: "regional-care-gap-rule-manual", percent: -5.7),
                RoundingRegionalCareGapRuleAdjuster(step: 0.1),
                MinimumRegionalCareGapRuleAdjuster(minimum: 47.5),
                CapRegionalCareGapRuleAdjuster(cap: 14052.0),
                TieredRegionalCareGapRuleAdjuster(bounds: [832.0, 2133.0, 6403.0], rates: [0.94, 1.15, 1.05]),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 7057.1
        )
    }
}
