import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the census template calculation.
    protocol CensusTemplateAdjuster {
        func describe() -> String
        func adjust(_ item: CensusTemplate, value: Double) -> Double
    }

    final class MinimumCensusTemplateAdjuster: CensusTemplateAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CensusTemplate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredCensusTemplateAdjuster: CensusTemplateAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CensusTemplate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CensusTemplateDurationMinutesOffsetAdjuster: CensusTemplateAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus duration minutes times \(weight)"
        }

        func adjust(_ item: CensusTemplate, value: Double) -> Double {
            return value + Double(item.durationMinutes) * weight
        }
    }

    final class PercentCensusTemplateAdjuster: CensusTemplateAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CensusTemplate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingCensusTemplateAdjuster: CensusTemplateAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CensusTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the census template steps in order and keeps a trace of each.
    final class CensusTemplateEngine {
        var steps: [any CensusTemplateAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CensusTemplateAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CensusTemplate) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any CensusTemplateAdjuster = steps[index]
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

        func evaluateAll(_ items: [CensusTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCensusTemplateEngine() -> CensusTemplateEngine {
        return CensusTemplateEngine(
            steps: [
                MinimumCensusTemplateAdjuster(minimum: 25.6),
                TieredCensusTemplateAdjuster(bounds: [757.0, 2744.0, 6246.0], rates: [0.97, 0.81, 1.06]),
                CensusTemplateDurationMinutesOffsetAdjuster(weight: 0.58),
                PercentCensusTemplateAdjuster(percent: 17.7),
                RoundingCensusTemplateAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 37864.4
        )
    }
}
