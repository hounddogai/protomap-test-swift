import AcmePlatform
import Foundation

extension Consent {
    /// One step of the tiered language template calculation.
    protocol TieredLanguageTemplateStep {
        func describe() -> String
        func adjust(_ item: TieredLanguageTemplate, value: Double) -> Double
    }

    final class TieredLanguageTemplateScoreOffsetAdjuster: TieredLanguageTemplateStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: TieredLanguageTemplate, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class RoundingTieredLanguageTemplateAdjuster: TieredLanguageTemplateStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredLanguageTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapTieredLanguageTemplateAdjuster: TieredLanguageTemplateStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredLanguageTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredTieredLanguageTemplateAdjuster: TieredLanguageTemplateStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredLanguageTemplate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the tiered language template steps in order and keeps a trace of each.
    final class TieredLanguageTemplateEngine {
        var steps: [any TieredLanguageTemplateStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredLanguageTemplateStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: TieredLanguageTemplate) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any TieredLanguageTemplateStep = steps[index]
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

        func evaluateAll(_ items: [TieredLanguageTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultTieredLanguageTemplateEngine() -> TieredLanguageTemplateEngine {
        return TieredLanguageTemplateEngine(
            steps: [
                TieredLanguageTemplateScoreOffsetAdjuster(weight: 1.16),
                RoundingTieredLanguageTemplateAdjuster(step: 0.1),
                CapTieredLanguageTemplateAdjuster(cap: 12130.0),
                TieredTieredLanguageTemplateAdjuster(bounds: [2758.0, 7450.0, 7954.0], rates: [1.09, 1.18, 1.02]),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 34748.1
        )
    }
}
