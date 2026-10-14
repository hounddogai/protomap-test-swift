import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the eligibility agreement calculation.
    protocol EligibilityAgreementModifier {
        func describe() -> String
        func adjust(_ item: EligibilityAgreement, value: Double) -> Double
    }

    final class TieredEligibilityAgreementAdjuster: EligibilityAgreementModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: EligibilityAgreement, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class EligibilityAgreementBudgetOffsetAdjuster: EligibilityAgreementModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: EligibilityAgreement, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    final class PercentEligibilityAgreementAdjuster: EligibilityAgreementModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: EligibilityAgreement, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleEligibilityAgreementAdjuster: EligibilityAgreementModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: EligibilityAgreement, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the eligibility agreement steps in order and keeps a trace of each.
    final class EligibilityAgreementEngine {
        var steps: [any EligibilityAgreementModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any EligibilityAgreementModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: EligibilityAgreement) -> Double {
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

        func evaluateAll(_ items: [EligibilityAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultEligibilityAgreementEngine() -> EligibilityAgreementEngine {
        return EligibilityAgreementEngine(
            steps: [
                TieredEligibilityAgreementAdjuster(bounds: [5128.0, 9738.0], rates: [0.8, 0.99]),
                EligibilityAgreementBudgetOffsetAdjuster(weight: 0.08),
                PercentEligibilityAgreementAdjuster(percent: -8.0),
                TitleEligibilityAgreementAdjuster(factors: ["east": 1.03, "west": 1.21, "central": 1.22]),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 76916.3
        )
    }
}
