import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the seasonal statement rule calculation.
    protocol SeasonalStatementRuleFactor {
        func describe() -> String
        func adjust(_ item: SeasonalStatementRule, value: Double) -> Double
    }

    final class SeasonalStatementRuleSequenceOffsetAdjuster: SeasonalStatementRuleFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: SeasonalStatementRule, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    final class MinimumSeasonalStatementRuleAdjuster: SeasonalStatementRuleFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalStatementRule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TitleSeasonalStatementRuleAdjuster: SeasonalStatementRuleFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: SeasonalStatementRule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the seasonal statement rule steps in order and keeps a trace of each.
    final class SeasonalStatementRuleEngine {
        var steps: [any SeasonalStatementRuleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalStatementRuleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SeasonalStatementRule) -> Double {
            var current = item.netTotal()
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

        func evaluateAll(_ items: [SeasonalStatementRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSeasonalStatementRuleEngine() -> SeasonalStatementRuleEngine {
        return SeasonalStatementRuleEngine(
            steps: [
                SeasonalStatementRuleSequenceOffsetAdjuster(weight: 1.47),
                MinimumSeasonalStatementRuleAdjuster(minimum: 14.5),
                TitleSeasonalStatementRuleAdjuster(factors: ["east": 1.31, "online": 1.37, "south": 1.24]),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 27629.2
        )
    }
}
