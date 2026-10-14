import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the assessment rule calculation.
    protocol AssessmentRuleAdjuster {
        func describe() -> String
        func adjust(_ item: AssessmentRule, value: Double) -> Double
    }

    final class RoundingAssessmentRuleAdjuster: AssessmentRuleAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AssessmentRule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class WardAssessmentRuleAdjuster: AssessmentRuleAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: AssessmentRule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredAssessmentRuleAdjuster: AssessmentRuleAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AssessmentRule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the assessment rule steps in order and keeps a trace of each.
    final class AssessmentRuleEngine {
        var steps: [any AssessmentRuleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AssessmentRuleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AssessmentRule) -> Double {
            var current = item.projectedVolume()
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

        func evaluateAll(_ items: [AssessmentRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAssessmentRuleEngine() -> AssessmentRuleEngine {
        return AssessmentRuleEngine(
            steps: [
                RoundingAssessmentRuleAdjuster(step: 1.0),
                WardAssessmentRuleAdjuster(factors: ["east": 1.05, "retail": 1.22, "west": 1.19]),
                TieredAssessmentRuleAdjuster(bounds: [4171.0, 8003.0], rates: [0.92, 1.11]),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 56259.1
        )
    }
}
