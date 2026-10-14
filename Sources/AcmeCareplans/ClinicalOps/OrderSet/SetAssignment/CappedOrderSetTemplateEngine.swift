import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the capped order set template calculation.
    protocol CappedOrderSetTemplateFactor {
        func describe() -> String
        func adjust(_ item: CappedOrderSetTemplate, value: Double) -> Double
    }

    final class PercentCappedOrderSetTemplateAdjuster: CappedOrderSetTemplateFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedOrderSetTemplate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumCappedOrderSetTemplateAdjuster: CappedOrderSetTemplateFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedOrderSetTemplate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingCappedOrderSetTemplateAdjuster: CappedOrderSetTemplateFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedOrderSetTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredCappedOrderSetTemplateAdjuster: CappedOrderSetTemplateFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedOrderSetTemplate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CappedOrderSetTemplateWeightOffsetAdjuster: CappedOrderSetTemplateFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus weight times \(weight)"
        }

        func adjust(_ item: CappedOrderSetTemplate, value: Double) -> Double {
            return value + item.weight * weight
        }
    }

    /// Runs the capped order set template steps in order and keeps a trace of each.
    final class CappedOrderSetTemplateEngine {
        var steps: [any CappedOrderSetTemplateFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedOrderSetTemplateFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CappedOrderSetTemplate) -> Double {
            var current = item.adjustedLoad()
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

        func evaluateAll(_ items: [CappedOrderSetTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCappedOrderSetTemplateEngine() -> CappedOrderSetTemplateEngine {
        return CappedOrderSetTemplateEngine(
            steps: [
                PercentCappedOrderSetTemplateAdjuster(percent: 21.9),
                MinimumCappedOrderSetTemplateAdjuster(minimum: 22.5),
                RoundingCappedOrderSetTemplateAdjuster(step: 0.1),
                TieredCappedOrderSetTemplateAdjuster(
                    bounds: [1700.0, 3296.0, 7321.0, 8486.0],
                    rates: [1.11, 0.95, 0.89, 1.13]
                ),
                CappedOrderSetTemplateWeightOffsetAdjuster(weight: 1.28),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 64943.3
        )
    }
}
