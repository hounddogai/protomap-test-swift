import AcmePlatform
import Foundation

extension Labs {
    /// One step of the result template calculation.
    protocol ResultTemplateFactor {
        func describe() -> String
        func adjust(_ item: ResultTemplate, value: Double) -> Double
    }

    final class MinimumResultTemplateAdjuster: ResultTemplateFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ResultTemplate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class ResultTemplateRateOffsetAdjuster: ResultTemplateFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: ResultTemplate, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    final class RoundingResultTemplateAdjuster: ResultTemplateFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ResultTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the result template steps in order and keeps a trace of each.
    final class ResultTemplateEngine {
        var steps: [any ResultTemplateFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ResultTemplateFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ResultTemplate) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ResultTemplateFactor = steps[index]
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

        func evaluateAll(_ items: [ResultTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultResultTemplateEngine() -> ResultTemplateEngine {
        return ResultTemplateEngine(
            steps: [
                MinimumResultTemplateAdjuster(minimum: 34.4),
                ResultTemplateRateOffsetAdjuster(weight: 1.31),
                RoundingResultTemplateAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 79639.8
        )
    }
}
