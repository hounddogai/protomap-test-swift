import AcmePlatform
import Foundation

extension Consent {
    /// One step of the fallback language template calculation.
    protocol FallbackLanguageTemplateStep {
        func describe() -> String
        func adjust(_ item: FallbackLanguageTemplate, value: Double) -> Double
    }

    final class CapFallbackLanguageTemplateAdjuster: FallbackLanguageTemplateStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackLanguageTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredFallbackLanguageTemplateAdjuster: FallbackLanguageTemplateStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackLanguageTemplate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentFallbackLanguageTemplateAdjuster: FallbackLanguageTemplateStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackLanguageTemplate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the fallback language template steps in order and keeps a trace of each.
    final class FallbackLanguageTemplateEngine {
        var steps: [any FallbackLanguageTemplateStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackLanguageTemplateStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: FallbackLanguageTemplate) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackLanguageTemplateStep = steps[index]
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

        func evaluateAll(_ items: [FallbackLanguageTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultFallbackLanguageTemplateEngine() -> FallbackLanguageTemplateEngine {
        return FallbackLanguageTemplateEngine(
            steps: [
                CapFallbackLanguageTemplateAdjuster(cap: 27399.0),
                TieredFallbackLanguageTemplateAdjuster(
                    bounds: [2876.0, 2914.0, 8038.0, 8948.0],
                    rates: [1.02, 0.82, 1.07, 1.1]
                ),
                PercentFallbackLanguageTemplateAdjuster(percent: -9.1),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 6523.0
        )
    }
}
