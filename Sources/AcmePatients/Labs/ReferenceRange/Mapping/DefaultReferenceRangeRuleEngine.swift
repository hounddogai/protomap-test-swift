import AcmePlatform
import Foundation

extension Labs {
    /// One step of the default reference range rule calculation.
    protocol DefaultReferenceRangeRuleStep {
        func describe() -> String
        func adjust(_ item: DefaultReferenceRangeRule, value: Double) -> Double
    }

    final class PercentDefaultReferenceRangeRuleAdjuster: DefaultReferenceRangeRuleStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultReferenceRangeRule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class DefaultReferenceRangeRuleQuantityOffsetAdjuster: DefaultReferenceRangeRuleStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: DefaultReferenceRangeRule, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class CountryDefaultReferenceRangeRuleAdjuster: DefaultReferenceRangeRuleStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: DefaultReferenceRangeRule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingDefaultReferenceRangeRuleAdjuster: DefaultReferenceRangeRuleStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultReferenceRangeRule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapDefaultReferenceRangeRuleAdjuster: DefaultReferenceRangeRuleStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultReferenceRangeRule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredDefaultReferenceRangeRuleAdjuster: DefaultReferenceRangeRuleStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultReferenceRangeRule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the default reference range rule steps in order and keeps a trace of each.
    final class DefaultReferenceRangeRuleEngine {
        var steps: [any DefaultReferenceRangeRuleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultReferenceRangeRuleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DefaultReferenceRangeRule) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultReferenceRangeRuleStep = steps[index]
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

        func evaluateAll(_ items: [DefaultReferenceRangeRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDefaultReferenceRangeRuleEngine() -> DefaultReferenceRangeRuleEngine {
        return DefaultReferenceRangeRuleEngine(
            steps: [
                PercentDefaultReferenceRangeRuleAdjuster(percent: 0.8),
                DefaultReferenceRangeRuleQuantityOffsetAdjuster(weight: 1.28),
                CountryDefaultReferenceRangeRuleAdjuster(factors: ["north": 1.36, "west": 0.84, "retail": 1.34]),
                RoundingDefaultReferenceRangeRuleAdjuster(step: 1.0),
                CapDefaultReferenceRangeRuleAdjuster(cap: 36179.0),
                TieredDefaultReferenceRangeRuleAdjuster(bounds: [6223.0, 7457.0], rates: [1.15, 1.12]),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 72911.2
        )
    }
}
