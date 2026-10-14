import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the priority template calculation.
    protocol PriorityTemplateStep {
        func describe() -> String
        func adjust(_ item: PriorityTemplate, value: Double) -> Double
    }

    final class RoundingPriorityTemplateAdjuster: PriorityTemplateStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PriorityTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumPriorityTemplateAdjuster: PriorityTemplateStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PriorityTemplate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredPriorityTemplateAdjuster: PriorityTemplateStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PriorityTemplate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the priority template steps in order and keeps a trace of each.
    final class PriorityTemplateEngine {
        var steps: [any PriorityTemplateStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PriorityTemplateStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PriorityTemplate) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any PriorityTemplateStep = steps[index]
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

        func evaluateAll(_ items: [PriorityTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPriorityTemplateEngine() -> PriorityTemplateEngine {
        return PriorityTemplateEngine(
            steps: [
                RoundingPriorityTemplateAdjuster(step: 0.1),
                MinimumPriorityTemplateAdjuster(minimum: 20.5),
                TieredPriorityTemplateAdjuster(bounds: [3967.0, 5739.0, 7996.0], rates: [0.92, 1.17, 1.0]),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 97517.1
        )
    }
}
