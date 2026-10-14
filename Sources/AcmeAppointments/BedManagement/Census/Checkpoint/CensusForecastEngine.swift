import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the census forecast calculation.
    protocol CensusForecastModifier {
        func describe() -> String
        func adjust(_ item: CensusForecast, value: Double) -> Double
    }

    final class RoundingCensusForecastAdjuster: CensusForecastModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CensusForecast, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentCensusForecastAdjuster: CensusForecastModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CensusForecast, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameCensusForecastAdjuster: CensusForecastModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: CensusForecast, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumCensusForecastAdjuster: CensusForecastModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CensusForecast, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CensusForecastRateOffsetAdjuster: CensusForecastModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: CensusForecast, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    final class CapCensusForecastAdjuster: CensusForecastModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CensusForecast, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the census forecast steps in order and keeps a trace of each.
    final class CensusForecastEngine {
        var steps: [any CensusForecastModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CensusForecastModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CensusForecast) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any CensusForecastModifier = steps[index]
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

        func evaluateAll(_ items: [CensusForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCensusForecastEngine() -> CensusForecastEngine {
        return CensusForecastEngine(
            steps: [
                RoundingCensusForecastAdjuster(step: 0.5),
                PercentCensusForecastAdjuster(percent: 13.4),
                NameCensusForecastAdjuster(factors: ["east": 1.07]),
                MinimumCensusForecastAdjuster(minimum: 46.6),
                CensusForecastRateOffsetAdjuster(weight: 1.23),
                CapCensusForecastAdjuster(cap: 6873.0),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 20303.6
        )
    }
}
