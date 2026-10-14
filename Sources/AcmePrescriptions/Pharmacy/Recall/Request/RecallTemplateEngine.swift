import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the recall template calculation.
    protocol RecallTemplateFactor {
        func describe() -> String
        func adjust(_ item: RecallTemplate, value: Double) -> Double
    }

    final class TieredRecallTemplateAdjuster: RecallTemplateFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RecallTemplate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapRecallTemplateAdjuster: RecallTemplateFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RecallTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentRecallTemplateAdjuster: RecallTemplateFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RecallTemplate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FacilityRecallTemplateAdjuster: RecallTemplateFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: RecallTemplate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingRecallTemplateAdjuster: RecallTemplateFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RecallTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the recall template steps in order and keeps a trace of each.
    final class RecallTemplateEngine {
        var steps: [any RecallTemplateFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RecallTemplateFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RecallTemplate) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RecallTemplateFactor = steps[index]
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

        func evaluateAll(_ items: [RecallTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRecallTemplateEngine() -> RecallTemplateEngine {
        return RecallTemplateEngine(
            steps: [
                TieredRecallTemplateAdjuster(bounds: [265.0, 5610.0, 6278.0, 7462.0], rates: [0.87, 1.18, 0.91, 0.81]),
                CapRecallTemplateAdjuster(cap: 17491.0),
                PercentRecallTemplateAdjuster(percent: 22.3),
                FacilityRecallTemplateAdjuster(factors: ["central": 1.25, "retail": 0.98]),
                RoundingRecallTemplateAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 17827.5
        )
    }
}
