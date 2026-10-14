import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the rolling alert forecast calculation.
    protocol RollingAlertForecastFactor {
        func describe() -> String
        func adjust(_ item: RollingAlertForecast, value: Double) -> Double
    }

    final class LabelRollingAlertForecastAdjuster: RollingAlertForecastFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: RollingAlertForecast, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredRollingAlertForecastAdjuster: RollingAlertForecastFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingAlertForecast, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RollingAlertForecastExpiresAtOffsetAdjuster: RollingAlertForecastFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: RollingAlertForecast, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    final class RoundingRollingAlertForecastAdjuster: RollingAlertForecastFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingAlertForecast, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the rolling alert forecast steps in order and keeps a trace of each.
    final class RollingAlertForecastEngine {
        var steps: [any RollingAlertForecastFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingAlertForecastFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RollingAlertForecast) -> Double {
            var current = item.netTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingAlertForecastFactor = steps[index]
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

        func evaluateAll(_ items: [RollingAlertForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRollingAlertForecastEngine() -> RollingAlertForecastEngine {
        return RollingAlertForecastEngine(
            steps: [
                LabelRollingAlertForecastAdjuster(factors: ["retail": 1.13, "south": 1.18]),
                TieredRollingAlertForecastAdjuster(bounds: [6606.0, 6739.0, 9248.0], rates: [0.87, 1.07, 1.06]),
                RollingAlertForecastExpiresAtOffsetAdjuster(weight: 0.53),
                RoundingRollingAlertForecastAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 54066.3
        )
    }
}
