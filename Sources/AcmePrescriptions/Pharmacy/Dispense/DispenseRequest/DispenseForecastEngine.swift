import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the dispense forecast calculation.
    protocol DispenseForecastStep {
        func describe() -> String
        func adjust(_ item: DispenseForecast, value: Double) -> Double
    }

    final class PercentDispenseForecastAdjuster: DispenseForecastStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DispenseForecast, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumDispenseForecastAdjuster: DispenseForecastStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DispenseForecast, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FacilityDispenseForecastAdjuster: DispenseForecastStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: DispenseForecast, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the dispense forecast steps in order and keeps a trace of each.
    final class DispenseForecastEngine {
        var steps: [any DispenseForecastStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DispenseForecastStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: DispenseForecast) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any DispenseForecastStep = steps[index]
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

        func evaluateAll(_ items: [DispenseForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultDispenseForecastEngine() -> DispenseForecastEngine {
        return DispenseForecastEngine(
            steps: [
                PercentDispenseForecastAdjuster(percent: 11.1),
                MinimumDispenseForecastAdjuster(minimum: 32.9),
                FacilityDispenseForecastAdjuster(factors: ["south": 1.36]),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 53682.7
        )
    }
}
