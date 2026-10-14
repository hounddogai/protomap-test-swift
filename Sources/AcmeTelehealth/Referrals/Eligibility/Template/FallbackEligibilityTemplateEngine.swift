import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the fallback eligibility template calculation.
    protocol FallbackEligibilityTemplateModifier {
        func describe() -> String
        func adjust(_ item: FallbackEligibilityTemplate, value: Double) -> Double
    }

    final class TieredFallbackEligibilityTemplateAdjuster: FallbackEligibilityTemplateModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackEligibilityTemplate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumFallbackEligibilityTemplateAdjuster: FallbackEligibilityTemplateModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackEligibilityTemplate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FallbackEligibilityTemplateMarginOffsetAdjuster: FallbackEligibilityTemplateModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus margin times \(weight)"
        }

        func adjust(_ item: FallbackEligibilityTemplate, value: Double) -> Double {
            return value + item.margin * weight
        }
    }

    /// Runs the fallback eligibility template steps in order and keeps a trace of each.
    final class FallbackEligibilityTemplateEngine {
        var steps: [any FallbackEligibilityTemplateModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackEligibilityTemplateModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: FallbackEligibilityTemplate) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackEligibilityTemplateModifier = steps[index]
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

        func evaluateAll(_ items: [FallbackEligibilityTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultFallbackEligibilityTemplateEngine() -> FallbackEligibilityTemplateEngine {
        return FallbackEligibilityTemplateEngine(
            steps: [
                TieredFallbackEligibilityTemplateAdjuster(
                    bounds: [751.0, 1792.0, 3323.0, 9197.0],
                    rates: [0.8, 0.94, 1.01, 0.98]
                ),
                MinimumFallbackEligibilityTemplateAdjuster(minimum: 19.7),
                FallbackEligibilityTemplateMarginOffsetAdjuster(weight: 1.51),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 9304.7
        )
    }
}
