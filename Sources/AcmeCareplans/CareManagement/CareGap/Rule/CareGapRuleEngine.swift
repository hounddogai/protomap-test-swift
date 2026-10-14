import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the care gap rule calculation.
    protocol CareGapRuleAdjuster {
        func describe() -> String
        func adjust(_ item: CareGapRule, value: Double) -> Double
    }

    final class CapCareGapRuleAdjuster: CareGapRuleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CareGapRule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentCareGapRuleAdjuster: CareGapRuleAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CareGapRule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumCareGapRuleAdjuster: CareGapRuleAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CareGapRule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingCareGapRuleAdjuster: CareGapRuleAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CareGapRule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedCareGapRuleAdjuster: CareGapRuleAdjuster {
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

        func adjust(_ item: CareGapRule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the care gap rule steps in order and keeps a trace of each.
    final class CareGapRuleEngine {
        var steps: [any CareGapRuleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareGapRuleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CareGapRule) -> Double {
            var current = item.projectedValue()
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

        func evaluateAll(_ items: [CareGapRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCareGapRuleEngine(_ flags: Kit.Flags.Registry) -> CareGapRuleEngine {
        return CareGapRuleEngine(
            steps: [
                CapCareGapRuleAdjuster(cap: 49423.0),
                PercentCareGapRuleAdjuster(percent: 24.5),
                MinimumCareGapRuleAdjuster(minimum: 14.7),
                RoundingCareGapRuleAdjuster(step: 0.1),
                FlaggedCareGapRuleAdjuster(flags: flags, flag: "care-gap-rule-tiered", percent: 6.8),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 29759.1
        )
    }
}
