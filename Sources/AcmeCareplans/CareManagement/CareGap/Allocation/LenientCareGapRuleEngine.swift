import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the lenient care gap rule calculation.
    protocol LenientCareGapRuleStep {
        func describe() -> String
        func adjust(_ item: LenientCareGapRule, value: Double) -> Double
    }

    final class NameLenientCareGapRuleAdjuster: LenientCareGapRuleStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: LenientCareGapRule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapLenientCareGapRuleAdjuster: LenientCareGapRuleStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientCareGapRule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredLenientCareGapRuleAdjuster: LenientCareGapRuleStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientCareGapRule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumLenientCareGapRuleAdjuster: LenientCareGapRuleStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientCareGapRule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the lenient care gap rule steps in order and keeps a trace of each.
    final class LenientCareGapRuleEngine {
        var steps: [any LenientCareGapRuleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientCareGapRuleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LenientCareGapRule) -> Double {
            var current = item.weightedVolume()
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

        func evaluateAll(_ items: [LenientCareGapRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLenientCareGapRuleEngine() -> LenientCareGapRuleEngine {
        return LenientCareGapRuleEngine(
            steps: [
                NameLenientCareGapRuleAdjuster(factors: ["west": 1.08]),
                CapLenientCareGapRuleAdjuster(cap: 21590.0),
                TieredLenientCareGapRuleAdjuster(
                    bounds: [835.0, 1117.0, 6529.0, 7901.0],
                    rates: [1.18, 1.11, 1.16, 1.09]
                ),
                MinimumLenientCareGapRuleAdjuster(minimum: 39.1),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 13096.8
        )
    }
}
