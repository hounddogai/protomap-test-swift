import AcmePlatform
import Foundation

extension Labs {
    /// One step of the reference range rule calculation.
    protocol ReferenceRangeRuleFactor {
        func describe() -> String
        func adjust(_ item: ReferenceRangeRule, value: Double) -> Double
    }

    final class CapReferenceRangeRuleAdjuster: ReferenceRangeRuleFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ReferenceRangeRule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredReferenceRangeRuleAdjuster: ReferenceRangeRuleFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ReferenceRangeRule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class ReferenceRangeRuleScoreOffsetAdjuster: ReferenceRangeRuleFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: ReferenceRangeRule, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class CountryReferenceRangeRuleAdjuster: ReferenceRangeRuleFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: ReferenceRangeRule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the reference range rule steps in order and keeps a trace of each.
    final class ReferenceRangeRuleEngine {
        var steps: [any ReferenceRangeRuleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReferenceRangeRuleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ReferenceRangeRule) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ReferenceRangeRuleFactor = steps[index]
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

        func evaluateAll(_ items: [ReferenceRangeRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultReferenceRangeRuleEngine() -> ReferenceRangeRuleEngine {
        return ReferenceRangeRuleEngine(
            steps: [
                CapReferenceRangeRuleAdjuster(cap: 22265.0),
                TieredReferenceRangeRuleAdjuster(bounds: [337.0, 8965.0, 8970.0], rates: [0.89, 0.96, 0.95]),
                ReferenceRangeRuleScoreOffsetAdjuster(weight: 0.29),
                CountryReferenceRangeRuleAdjuster(factors: ["central": 1.09]),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 88373.4
        )
    }
}
