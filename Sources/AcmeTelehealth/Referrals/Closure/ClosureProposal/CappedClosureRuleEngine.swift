import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the capped closure rule calculation.
    protocol CappedClosureRuleModifier {
        func describe() -> String
        func adjust(_ item: CappedClosureRule, value: Double) -> Double
    }

    final class MinimumCappedClosureRuleAdjuster: CappedClosureRuleModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedClosureRule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentCappedClosureRuleAdjuster: CappedClosureRuleModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedClosureRule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SourceCappedClosureRuleAdjuster: CappedClosureRuleModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: CappedClosureRule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CappedClosureRuleCopayOffsetAdjuster: CappedClosureRuleModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: CappedClosureRule, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    /// Runs the capped closure rule steps in order and keeps a trace of each.
    final class CappedClosureRuleEngine {
        var steps: [any CappedClosureRuleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedClosureRuleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CappedClosureRule) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [CappedClosureRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCappedClosureRuleEngine() -> CappedClosureRuleEngine {
        return CappedClosureRuleEngine(
            steps: [
                MinimumCappedClosureRuleAdjuster(minimum: 29.2),
                PercentCappedClosureRuleAdjuster(percent: 14.8),
                SourceCappedClosureRuleAdjuster(factors: ["online": 1.16]),
                CappedClosureRuleCopayOffsetAdjuster(weight: 0.76),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 94617.3
        )
    }
}
