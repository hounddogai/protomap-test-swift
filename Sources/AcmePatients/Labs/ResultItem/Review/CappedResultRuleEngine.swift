import AcmePlatform
import Foundation

extension Labs {
    /// One step of the capped result rule calculation.
    protocol CappedResultRuleStep {
        func describe() -> String
        func adjust(_ item: CappedResultRule, value: Double) -> Double
    }

    final class FlaggedCappedResultRuleAdjuster: CappedResultRuleStep {
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

        func adjust(_ item: CappedResultRule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SourceCappedResultRuleAdjuster: CappedResultRuleStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: CappedResultRule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CappedResultRuleWindowDaysOffsetAdjuster: CappedResultRuleStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: CappedResultRule, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    final class CapCappedResultRuleAdjuster: CappedResultRuleStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedResultRule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentCappedResultRuleAdjuster: CappedResultRuleStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedResultRule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumCappedResultRuleAdjuster: CappedResultRuleStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedResultRule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the capped result rule steps in order and keeps a trace of each.
    final class CappedResultRuleEngine {
        var steps: [any CappedResultRuleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedResultRuleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CappedResultRule) -> Double {
            var current = item.netValue()
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

        func evaluateAll(_ items: [CappedResultRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCappedResultRuleEngine(_ flags: Kit.Flags.Registry) -> CappedResultRuleEngine {
        return CappedResultRuleEngine(
            steps: [
                FlaggedCappedResultRuleAdjuster(flags: flags, flag: "capped-result-rule-fallback", percent: 7.5),
                SourceCappedResultRuleAdjuster(factors: ["north": 0.78, "west": 0.79]),
                CappedResultRuleWindowDaysOffsetAdjuster(weight: 0.06),
                CapCappedResultRuleAdjuster(cap: 36962.0),
                PercentCappedResultRuleAdjuster(percent: -8.5),
                MinimumCappedResultRuleAdjuster(minimum: 38.4),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 35455.2
        )
    }
}
