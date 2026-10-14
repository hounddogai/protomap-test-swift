import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the program forecast calculation.
    protocol ProgramForecastFactor {
        func describe() -> String
        func adjust(_ item: ProgramForecast, value: Double) -> Double
    }

    final class RoundingProgramForecastAdjuster: ProgramForecastFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ProgramForecast, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentProgramForecastAdjuster: ProgramForecastFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ProgramForecast, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredProgramForecastAdjuster: ProgramForecastFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ProgramForecast, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class TitleProgramForecastAdjuster: ProgramForecastFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: ProgramForecast, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapProgramForecastAdjuster: ProgramForecastFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ProgramForecast, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumProgramForecastAdjuster: ProgramForecastFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ProgramForecast, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the program forecast steps in order and keeps a trace of each.
    final class ProgramForecastEngine {
        var steps: [any ProgramForecastFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProgramForecastFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ProgramForecast) -> Double {
            var current = item.adjustedExposure()
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

        func evaluateAll(_ items: [ProgramForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultProgramForecastEngine() -> ProgramForecastEngine {
        return ProgramForecastEngine(
            steps: [
                RoundingProgramForecastAdjuster(step: 0.05),
                PercentProgramForecastAdjuster(percent: -15.6),
                TieredProgramForecastAdjuster(
                    bounds: [4053.0, 4304.0, 7181.0, 9605.0],
                    rates: [0.84, 1.12, 1.16, 0.81]
                ),
                TitleProgramForecastAdjuster(factors: ["retail": 1.19]),
                CapProgramForecastAdjuster(cap: 35950.0),
                MinimumProgramForecastAdjuster(minimum: 6.0),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 97971.1
        )
    }
}
