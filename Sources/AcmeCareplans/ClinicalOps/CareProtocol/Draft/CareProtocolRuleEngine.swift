import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the care protocol rule calculation.
    protocol CareProtocolRuleStep {
        func describe() -> String
        func adjust(_ item: CareProtocolRule, value: Double) -> Double
    }

    final class RoundingCareProtocolRuleAdjuster: CareProtocolRuleStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CareProtocolRule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedCareProtocolRuleAdjuster: CareProtocolRuleStep {
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

        func adjust(_ item: CareProtocolRule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumCareProtocolRuleAdjuster: CareProtocolRuleStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CareProtocolRule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CareProtocolRuleCopayOffsetAdjuster: CareProtocolRuleStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: CareProtocolRule, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    final class PercentCareProtocolRuleAdjuster: CareProtocolRuleStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CareProtocolRule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the care protocol rule steps in order and keeps a trace of each.
    final class CareProtocolRuleEngine {
        var steps: [any CareProtocolRuleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareProtocolRuleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CareProtocolRule) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any CareProtocolRuleStep = steps[index]
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

        func evaluateAll(_ items: [CareProtocolRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCareProtocolRuleEngine(_ flags: Kit.Flags.Registry) -> CareProtocolRuleEngine {
        return CareProtocolRuleEngine(
            steps: [
                RoundingCareProtocolRuleAdjuster(step: 5.0),
                FlaggedCareProtocolRuleAdjuster(flags: flags, flag: "care-protocol-rule-capped", percent: 2.0),
                MinimumCareProtocolRuleAdjuster(minimum: 14.8),
                CareProtocolRuleCopayOffsetAdjuster(weight: 1.16),
                PercentCareProtocolRuleAdjuster(percent: 19.0),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 57487.4
        )
    }
}
