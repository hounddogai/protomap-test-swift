import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the order set forecast calculation.
    protocol OrderSetForecastStep {
        func describe() -> String
        func adjust(_ item: OrderSetForecast, value: Double) -> Double
    }

    final class LabelOrderSetForecastAdjuster: OrderSetForecastStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: OrderSetForecast, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedOrderSetForecastAdjuster: OrderSetForecastStep {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: OrderSetForecast, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentOrderSetForecastAdjuster: OrderSetForecastStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: OrderSetForecast, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredOrderSetForecastAdjuster: OrderSetForecastStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: OrderSetForecast, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the order set forecast steps in order and keeps a trace of each.
    final class OrderSetForecastEngine {
        var steps: [any OrderSetForecastStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OrderSetForecastStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: OrderSetForecast) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any OrderSetForecastStep = steps[index]
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

        func evaluateAll(_ items: [OrderSetForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultOrderSetForecastEngine(_ flags: Kit.Flags.Registry) -> OrderSetForecastEngine {
        return OrderSetForecastEngine(
            steps: [
                LabelOrderSetForecastAdjuster(factors: ["retail": 1.24]),
                FlaggedOrderSetForecastAdjuster(flags: flags, flag: "order-set-forecast-weighted", percent: -9.2),
                PercentOrderSetForecastAdjuster(percent: -0.1),
                TieredOrderSetForecastAdjuster(bounds: [2303.0, 4482.0, 8715.0], rates: [1.08, 0.81, 0.82]),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 17348.1
        )
    }
}
