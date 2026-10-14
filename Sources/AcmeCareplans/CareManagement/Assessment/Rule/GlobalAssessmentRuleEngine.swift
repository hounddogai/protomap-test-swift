import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the global assessment rule calculation.
    protocol GlobalAssessmentRuleModifier {
        func describe() -> String
        func adjust(_ item: GlobalAssessmentRule, value: Double) -> Double
    }

    final class TieredGlobalAssessmentRuleAdjuster: GlobalAssessmentRuleModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalAssessmentRule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumGlobalAssessmentRuleAdjuster: GlobalAssessmentRuleModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalAssessmentRule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class NameGlobalAssessmentRuleAdjuster: GlobalAssessmentRuleModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: GlobalAssessmentRule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the global assessment rule steps in order and keeps a trace of each.
    final class GlobalAssessmentRuleEngine {
        var steps: [any GlobalAssessmentRuleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalAssessmentRuleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: GlobalAssessmentRule) -> Double {
            var current = item.weightedExposure()
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

        func evaluateAll(_ items: [GlobalAssessmentRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultGlobalAssessmentRuleEngine() -> GlobalAssessmentRuleEngine {
        return GlobalAssessmentRuleEngine(
            steps: [
                TieredGlobalAssessmentRuleAdjuster(bounds: [1113.0, 5365.0], rates: [1.14, 1.14]),
                MinimumGlobalAssessmentRuleAdjuster(minimum: 37.4),
                NameGlobalAssessmentRuleAdjuster(factors: ["north": 0.94, "retail": 1.05]),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 84991.1
        )
    }
}
