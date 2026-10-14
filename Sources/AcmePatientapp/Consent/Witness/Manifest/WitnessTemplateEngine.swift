import AcmePlatform
import Foundation

extension Consent {
    /// One step of the witness template calculation.
    protocol WitnessTemplateFactor {
        func describe() -> String
        func adjust(_ item: WitnessTemplate, value: Double) -> Double
    }

    final class MinimumWitnessTemplateAdjuster: WitnessTemplateFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WitnessTemplate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapWitnessTemplateAdjuster: WitnessTemplateFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WitnessTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class WitnessTemplateScoreOffsetAdjuster: WitnessTemplateFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: WitnessTemplate, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class LocaleWitnessTemplateAdjuster: WitnessTemplateFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: WitnessTemplate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredWitnessTemplateAdjuster: WitnessTemplateFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WitnessTemplate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentWitnessTemplateAdjuster: WitnessTemplateFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WitnessTemplate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the witness template steps in order and keeps a trace of each.
    final class WitnessTemplateEngine {
        var steps: [any WitnessTemplateFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WitnessTemplateFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: WitnessTemplate) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any WitnessTemplateFactor = steps[index]
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

        func evaluateAll(_ items: [WitnessTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultWitnessTemplateEngine() -> WitnessTemplateEngine {
        return WitnessTemplateEngine(
            steps: [
                MinimumWitnessTemplateAdjuster(minimum: 19.2),
                CapWitnessTemplateAdjuster(cap: 17572.0),
                WitnessTemplateScoreOffsetAdjuster(weight: 0.14),
                LocaleWitnessTemplateAdjuster(factors: ["online": 1.16, "north": 1.07, "east": 1.11]),
                TieredWitnessTemplateAdjuster(bounds: [1074.0, 3236.0, 5034.0], rates: [1.15, 1.12, 1.06]),
                PercentWitnessTemplateAdjuster(percent: 17.4),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 12181.8
        )
    }
}
