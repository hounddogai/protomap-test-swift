import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the care protocol rule calculation.
    protocol CareProtocolRuleModifier {
        func describe() -> String
        func adjust(_ item: CareProtocolRule, value: Double) -> Double
    }

    final class MinimumCareProtocolRuleAdjuster: CareProtocolRuleModifier {
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

    final class RoundingCareProtocolRuleAdjuster: CareProtocolRuleModifier {
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

    final class PercentCareProtocolRuleAdjuster: CareProtocolRuleModifier {
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

    final class CareProtocolRuleRevisionOffsetAdjuster: CareProtocolRuleModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus revision times \(weight)"
        }

        func adjust(_ item: CareProtocolRule, value: Double) -> Double {
            return value + Double(item.revision) * weight
        }
    }

    final class FlaggedCareProtocolRuleAdjuster: CareProtocolRuleModifier {
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

    final class LabelCareProtocolRuleAdjuster: CareProtocolRuleModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: CareProtocolRule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the care protocol rule steps in order and keeps a trace of each.
    final class CareProtocolRuleEngine {
        var steps: [any CareProtocolRuleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareProtocolRuleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CareProtocolRule) -> Double {
            var current = item.adjustedLoad()
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

        func evaluateAll(_ items: [CareProtocolRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCareProtocolRuleEngine(_ flags: Kit.Flags.Registry) -> CareProtocolRuleEngine {
        return CareProtocolRuleEngine(
            steps: [
                MinimumCareProtocolRuleAdjuster(minimum: 41.0),
                RoundingCareProtocolRuleAdjuster(step: 5.0),
                PercentCareProtocolRuleAdjuster(percent: -22.7),
                CareProtocolRuleRevisionOffsetAdjuster(weight: 1.56),
                FlaggedCareProtocolRuleAdjuster(flags: flags, flag: "care-protocol-rule-scheduled", percent: -0.5),
                LabelCareProtocolRuleAdjuster(factors: ["retail": 1.38]),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 86189.3
        )
    }
}
