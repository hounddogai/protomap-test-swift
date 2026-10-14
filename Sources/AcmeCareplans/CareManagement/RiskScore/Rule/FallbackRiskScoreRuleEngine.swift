import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the fallback risk score rule calculation.
    protocol FallbackRiskScoreRuleFactor {
        func describe() -> String
        func adjust(_ item: FallbackRiskScoreRule, value: Double) -> Double
    }

    final class RoundingFallbackRiskScoreRuleAdjuster: FallbackRiskScoreRuleFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackRiskScoreRule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FallbackRiskScoreRuleQuantityOffsetAdjuster: FallbackRiskScoreRuleFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: FallbackRiskScoreRule, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class TieredFallbackRiskScoreRuleAdjuster: FallbackRiskScoreRuleFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackRiskScoreRule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapFallbackRiskScoreRuleAdjuster: FallbackRiskScoreRuleFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackRiskScoreRule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumFallbackRiskScoreRuleAdjuster: FallbackRiskScoreRuleFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackRiskScoreRule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LabelFallbackRiskScoreRuleAdjuster: FallbackRiskScoreRuleFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: FallbackRiskScoreRule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the fallback risk score rule steps in order and keeps a trace of each.
    final class FallbackRiskScoreRuleEngine {
        var steps: [any FallbackRiskScoreRuleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackRiskScoreRuleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: FallbackRiskScoreRule) -> Double {
            var current = item.adjustedExposure()
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

        func evaluateAll(_ items: [FallbackRiskScoreRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultFallbackRiskScoreRuleEngine() -> FallbackRiskScoreRuleEngine {
        return FallbackRiskScoreRuleEngine(
            steps: [
                RoundingFallbackRiskScoreRuleAdjuster(step: 1.0),
                FallbackRiskScoreRuleQuantityOffsetAdjuster(weight: 0.81),
                TieredFallbackRiskScoreRuleAdjuster(
                    bounds: [732.0, 1484.0, 2518.0, 8386.0],
                    rates: [1.11, 0.91, 0.92, 0.89]
                ),
                CapFallbackRiskScoreRuleAdjuster(cap: 22026.0),
                MinimumFallbackRiskScoreRuleAdjuster(minimum: 38.1),
                LabelFallbackRiskScoreRuleAdjuster(factors: ["north": 1.01, "south": 0.78, "retail": 0.79]),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 72956.3
        )
    }
}
