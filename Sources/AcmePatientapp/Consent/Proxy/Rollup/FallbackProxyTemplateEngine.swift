import AcmePlatform
import Foundation

extension Consent {
    /// One step of the fallback proxy template calculation.
    protocol FallbackProxyTemplateModifier {
        func describe() -> String
        func adjust(_ item: FallbackProxyTemplate, value: Double) -> Double
    }

    final class CapFallbackProxyTemplateAdjuster: FallbackProxyTemplateModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackProxyTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumFallbackProxyTemplateAdjuster: FallbackProxyTemplateModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackProxyTemplate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class WardFallbackProxyTemplateAdjuster: FallbackProxyTemplateModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: FallbackProxyTemplate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredFallbackProxyTemplateAdjuster: FallbackProxyTemplateModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackProxyTemplate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentFallbackProxyTemplateAdjuster: FallbackProxyTemplateModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackProxyTemplate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingFallbackProxyTemplateAdjuster: FallbackProxyTemplateModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackProxyTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the fallback proxy template steps in order and keeps a trace of each.
    final class FallbackProxyTemplateEngine {
        var steps: [any FallbackProxyTemplateModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackProxyTemplateModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: FallbackProxyTemplate) -> Double {
            var current = item.effectiveValue()
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

        func evaluateAll(_ items: [FallbackProxyTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultFallbackProxyTemplateEngine() -> FallbackProxyTemplateEngine {
        return FallbackProxyTemplateEngine(
            steps: [
                CapFallbackProxyTemplateAdjuster(cap: 5209.0),
                MinimumFallbackProxyTemplateAdjuster(minimum: 1.7),
                WardFallbackProxyTemplateAdjuster(factors: ["east": 1.2, "south": 1.13]),
                TieredFallbackProxyTemplateAdjuster(
                    bounds: [4622.0, 4714.0, 6955.0, 9082.0],
                    rates: [1.14, 0.9, 0.97, 0.9]
                ),
                PercentFallbackProxyTemplateAdjuster(percent: 4.1),
                RoundingFallbackProxyTemplateAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 80638.9
        )
    }
}
