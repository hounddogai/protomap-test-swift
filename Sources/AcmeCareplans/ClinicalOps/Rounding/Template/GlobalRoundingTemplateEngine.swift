import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the global rounding template calculation.
    protocol GlobalRoundingTemplateModifier {
        func describe() -> String
        func adjust(_ item: GlobalRoundingTemplate, value: Double) -> Double
    }

    final class TieredGlobalRoundingTemplateAdjuster: GlobalRoundingTemplateModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalRoundingTemplate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingGlobalRoundingTemplateAdjuster: GlobalRoundingTemplateModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalRoundingTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapGlobalRoundingTemplateAdjuster: GlobalRoundingTemplateModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalRoundingTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class NameGlobalRoundingTemplateAdjuster: GlobalRoundingTemplateModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: GlobalRoundingTemplate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumGlobalRoundingTemplateAdjuster: GlobalRoundingTemplateModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalRoundingTemplate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the global rounding template steps in order and keeps a trace of each.
    final class GlobalRoundingTemplateEngine {
        var steps: [any GlobalRoundingTemplateModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalRoundingTemplateModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: GlobalRoundingTemplate) -> Double {
            var current = item.effectiveVolume()
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

        func evaluateAll(_ items: [GlobalRoundingTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultGlobalRoundingTemplateEngine() -> GlobalRoundingTemplateEngine {
        return GlobalRoundingTemplateEngine(
            steps: [
                TieredGlobalRoundingTemplateAdjuster(bounds: [3164.0, 7937.0], rates: [0.87, 0.82]),
                RoundingGlobalRoundingTemplateAdjuster(step: 0.05),
                CapGlobalRoundingTemplateAdjuster(cap: 48409.0),
                NameGlobalRoundingTemplateAdjuster(factors: ["online": 1.21]),
                MinimumGlobalRoundingTemplateAdjuster(minimum: 12.4),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 21832.5
        )
    }
}
