import AcmePlatform
import Foundation

extension Labs {
    /// One step of the seasonal courier template calculation.
    protocol SeasonalCourierTemplateAdjuster {
        func describe() -> String
        func adjust(_ item: SeasonalCourierTemplate, value: Double) -> Double
    }

    final class TieredSeasonalCourierTemplateAdjuster: SeasonalCourierTemplateAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalCourierTemplate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingSeasonalCourierTemplateAdjuster: SeasonalCourierTemplateAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalCourierTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumSeasonalCourierTemplateAdjuster: SeasonalCourierTemplateAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalCourierTemplate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the seasonal courier template steps in order and keeps a trace of each.
    final class SeasonalCourierTemplateEngine {
        var steps: [any SeasonalCourierTemplateAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalCourierTemplateAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: SeasonalCourierTemplate) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalCourierTemplateAdjuster = steps[index]
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

        func evaluateAll(_ items: [SeasonalCourierTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultSeasonalCourierTemplateEngine() -> SeasonalCourierTemplateEngine {
        return SeasonalCourierTemplateEngine(
            steps: [
                TieredSeasonalCourierTemplateAdjuster(
                    bounds: [2819.0, 4654.0, 6810.0, 9238.0],
                    rates: [0.8, 1.05, 1.14, 0.91]
                ),
                RoundingSeasonalCourierTemplateAdjuster(step: 5.0),
                MinimumSeasonalCourierTemplateAdjuster(minimum: 43.5),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 57751.2
        )
    }
}
