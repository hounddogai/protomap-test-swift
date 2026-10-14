import AcmePlatform
import Foundation

extension Consent {
    /// One step of the adaptive language template calculation.
    protocol AdaptiveLanguageTemplateAdjuster {
        func describe() -> String
        func adjust(_ item: AdaptiveLanguageTemplate, value: Double) -> Double
    }

    final class PercentAdaptiveLanguageTemplateAdjuster: AdaptiveLanguageTemplateAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveLanguageTemplate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredAdaptiveLanguageTemplateAdjuster: AdaptiveLanguageTemplateAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveLanguageTemplate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumAdaptiveLanguageTemplateAdjuster: AdaptiveLanguageTemplateAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveLanguageTemplate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class AdaptiveLanguageTemplateWindowDaysOffsetAdjuster: AdaptiveLanguageTemplateAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: AdaptiveLanguageTemplate, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    final class TitleAdaptiveLanguageTemplateAdjuster: AdaptiveLanguageTemplateAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: AdaptiveLanguageTemplate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingAdaptiveLanguageTemplateAdjuster: AdaptiveLanguageTemplateAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveLanguageTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the adaptive language template steps in order and keeps a trace of each.
    final class AdaptiveLanguageTemplateEngine {
        var steps: [any AdaptiveLanguageTemplateAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveLanguageTemplateAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AdaptiveLanguageTemplate) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveLanguageTemplateAdjuster = steps[index]
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

        func evaluateAll(_ items: [AdaptiveLanguageTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAdaptiveLanguageTemplateEngine() -> AdaptiveLanguageTemplateEngine {
        return AdaptiveLanguageTemplateEngine(
            steps: [
                PercentAdaptiveLanguageTemplateAdjuster(percent: -20.3),
                TieredAdaptiveLanguageTemplateAdjuster(bounds: [1084.0, 7103.0], rates: [1.03, 1.16]),
                MinimumAdaptiveLanguageTemplateAdjuster(minimum: 14.8),
                AdaptiveLanguageTemplateWindowDaysOffsetAdjuster(weight: 0.5),
                TitleAdaptiveLanguageTemplateAdjuster(factors: ["north": 1.26, "west": 1.26, "retail": 1.37]),
                RoundingAdaptiveLanguageTemplateAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 55743.8
        )
    }
}
