import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the read forecast calculation.
    protocol ReadForecastStep {
        func describe() -> String
        func adjust(_ item: ReadForecast, value: Double) -> Double
    }

    final class LabelReadForecastAdjuster: ReadForecastStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: ReadForecast, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredReadForecastAdjuster: ReadForecastStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ReadForecast, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedReadForecastAdjuster: ReadForecastStep {
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

        func adjust(_ item: ReadForecast, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the read forecast steps in order and keeps a trace of each.
    final class ReadForecastEngine {
        var steps: [any ReadForecastStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReadForecastStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ReadForecast) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ReadForecastStep = steps[index]
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

        func evaluateAll(_ items: [ReadForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultReadForecastEngine(_ flags: Kit.Flags.Registry) -> ReadForecastEngine {
        return ReadForecastEngine(
            steps: [
                LabelReadForecastAdjuster(factors: ["online": 0.74]),
                TieredReadForecastAdjuster(bounds: [1157.0, 2098.0, 5500.0], rates: [1.06, 1.07, 1.05]),
                FlaggedReadForecastAdjuster(flags: flags, flag: "read-forecast-regional", percent: -9.7),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 75445.1
        )
    }
}
