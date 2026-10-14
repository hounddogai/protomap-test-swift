import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the legacy remittance rule calculation.
    protocol LegacyRemittanceRuleStep {
        func describe() -> String
        func adjust(_ item: LegacyRemittanceRule, value: Double) -> Double
    }

    final class LegacyRemittanceRuleBatchSizeOffsetAdjuster: LegacyRemittanceRuleStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: LegacyRemittanceRule, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    final class TieredLegacyRemittanceRuleAdjuster: LegacyRemittanceRuleStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyRemittanceRule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class NameLegacyRemittanceRuleAdjuster: LegacyRemittanceRuleStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: LegacyRemittanceRule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the legacy remittance rule steps in order and keeps a trace of each.
    final class LegacyRemittanceRuleEngine {
        var steps: [any LegacyRemittanceRuleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyRemittanceRuleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LegacyRemittanceRule) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyRemittanceRuleStep = steps[index]
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

        func evaluateAll(_ items: [LegacyRemittanceRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLegacyRemittanceRuleEngine() -> LegacyRemittanceRuleEngine {
        return LegacyRemittanceRuleEngine(
            steps: [
                LegacyRemittanceRuleBatchSizeOffsetAdjuster(weight: 1.7),
                TieredLegacyRemittanceRuleAdjuster(bounds: [3920.0, 8778.0], rates: [0.88, 1.02]),
                NameLegacyRemittanceRuleAdjuster(factors: ["central": 1.25, "west": 0.75]),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 15540.9
        )
    }
}
