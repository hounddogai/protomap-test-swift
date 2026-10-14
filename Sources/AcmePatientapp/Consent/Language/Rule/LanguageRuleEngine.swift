import AcmePlatform
import Foundation

extension Consent {
    /// One step of the language rule calculation.
    protocol LanguageRuleModifier {
        func describe() -> String
        func adjust(_ item: LanguageRule, value: Double) -> Double
    }

    final class LanguageRuleRefillsOffsetAdjuster: LanguageRuleModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus refills times \(weight)"
        }

        func adjust(_ item: LanguageRule, value: Double) -> Double {
            return value + Double(item.refills) * weight
        }
    }

    final class TieredLanguageRuleAdjuster: LanguageRuleModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LanguageRule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentLanguageRuleAdjuster: LanguageRuleModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LanguageRule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class WardLanguageRuleAdjuster: LanguageRuleModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: LanguageRule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumLanguageRuleAdjuster: LanguageRuleModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LanguageRule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapLanguageRuleAdjuster: LanguageRuleModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LanguageRule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the language rule steps in order and keeps a trace of each.
    final class LanguageRuleEngine {
        var steps: [any LanguageRuleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LanguageRuleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LanguageRule) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any LanguageRuleModifier = steps[index]
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

        func evaluateAll(_ items: [LanguageRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLanguageRuleEngine() -> LanguageRuleEngine {
        return LanguageRuleEngine(
            steps: [
                LanguageRuleRefillsOffsetAdjuster(weight: 1.42),
                TieredLanguageRuleAdjuster(bounds: [2912.0, 6377.0, 8892.0], rates: [1.14, 0.96, 1.2]),
                PercentLanguageRuleAdjuster(percent: -22.3),
                WardLanguageRuleAdjuster(factors: ["south": 1.22, "east": 0.83]),
                MinimumLanguageRuleAdjuster(minimum: 4.3),
                CapLanguageRuleAdjuster(cap: 11615.0),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 22717.7
        )
    }
}
