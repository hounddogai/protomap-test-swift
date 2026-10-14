import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the regional follow up rule calculation.
    protocol RegionalFollowUpRuleModifier {
        func describe() -> String
        func adjust(_ item: RegionalFollowUpRule, value: Double) -> Double
    }

    final class PercentRegionalFollowUpRuleAdjuster: RegionalFollowUpRuleModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalFollowUpRule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumRegionalFollowUpRuleAdjuster: RegionalFollowUpRuleModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalFollowUpRule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class NameRegionalFollowUpRuleAdjuster: RegionalFollowUpRuleModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: RegionalFollowUpRule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the regional follow up rule steps in order and keeps a trace of each.
    final class RegionalFollowUpRuleEngine {
        var steps: [any RegionalFollowUpRuleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalFollowUpRuleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RegionalFollowUpRule) -> Double {
            var current = item.projectedLoad()
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

        func evaluateAll(_ items: [RegionalFollowUpRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRegionalFollowUpRuleEngine() -> RegionalFollowUpRuleEngine {
        return RegionalFollowUpRuleEngine(
            steps: [
                PercentRegionalFollowUpRuleAdjuster(percent: 13.6),
                MinimumRegionalFollowUpRuleAdjuster(minimum: 31.6),
                NameRegionalFollowUpRuleAdjuster(factors: ["online": 0.99]),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 84132.9
        )
    }
}
