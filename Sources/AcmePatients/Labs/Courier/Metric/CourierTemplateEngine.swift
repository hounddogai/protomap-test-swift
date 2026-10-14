import AcmePlatform
import Foundation

extension Labs {
    /// One step of the courier template calculation.
    protocol CourierTemplateFactor {
        func describe() -> String
        func adjust(_ item: CourierTemplate, value: Double) -> Double
    }

    final class RoundingCourierTemplateAdjuster: CourierTemplateFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CourierTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredCourierTemplateAdjuster: CourierTemplateFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CourierTemplate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumCourierTemplateAdjuster: CourierTemplateFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CourierTemplate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the courier template steps in order and keeps a trace of each.
    final class CourierTemplateEngine {
        var steps: [any CourierTemplateFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CourierTemplateFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CourierTemplate) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any CourierTemplateFactor = steps[index]
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

        func evaluateAll(_ items: [CourierTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCourierTemplateEngine() -> CourierTemplateEngine {
        return CourierTemplateEngine(
            steps: [
                RoundingCourierTemplateAdjuster(step: 5.0),
                TieredCourierTemplateAdjuster(bounds: [884.0, 4769.0, 7891.0], rates: [1.13, 0.8, 0.86]),
                MinimumCourierTemplateAdjuster(minimum: 14.4),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 57180.4
        )
    }
}
