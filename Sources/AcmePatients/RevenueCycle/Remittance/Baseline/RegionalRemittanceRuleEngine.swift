import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the regional remittance rule calculation.
    protocol RegionalRemittanceRuleAdjuster {
        func describe() -> String
        func adjust(_ item: RegionalRemittanceRule, value: Double) -> Double
    }

    final class CapRegionalRemittanceRuleAdjuster: RegionalRemittanceRuleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalRemittanceRule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingRegionalRemittanceRuleAdjuster: RegionalRemittanceRuleAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalRemittanceRule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentRegionalRemittanceRuleAdjuster: RegionalRemittanceRuleAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalRemittanceRule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedRegionalRemittanceRuleAdjuster: RegionalRemittanceRuleAdjuster {
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

        func adjust(_ item: RegionalRemittanceRule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RegionalRemittanceRuleMinimumOffsetAdjuster: RegionalRemittanceRuleAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: RegionalRemittanceRule, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    final class MinimumRegionalRemittanceRuleAdjuster: RegionalRemittanceRuleAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalRemittanceRule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the regional remittance rule steps in order and keeps a trace of each.
    final class RegionalRemittanceRuleEngine {
        var steps: [any RegionalRemittanceRuleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalRemittanceRuleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RegionalRemittanceRule) -> Double {
            var current = item.netLoad()
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

        func evaluateAll(_ items: [RegionalRemittanceRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRegionalRemittanceRuleEngine(_ flags: Kit.Flags.Registry) -> RegionalRemittanceRuleEngine {
        return RegionalRemittanceRuleEngine(
            steps: [
                CapRegionalRemittanceRuleAdjuster(cap: 19363.0),
                RoundingRegionalRemittanceRuleAdjuster(step: 0.25),
                PercentRegionalRemittanceRuleAdjuster(percent: -10.5),
                FlaggedRegionalRemittanceRuleAdjuster(
                    flags: flags,
                    flag: "regional-remittance-rule-legacy",
                    percent: 1.7
                ),
                RegionalRemittanceRuleMinimumOffsetAdjuster(weight: 1.05),
                MinimumRegionalRemittanceRuleAdjuster(minimum: 0.3),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 64480.8
        )
    }
}
