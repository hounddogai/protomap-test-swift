import AcmePlatform
import Foundation

extension Consent {
    /// One step of the batched witness forecast calculation.
    protocol BatchedWitnessForecastAdjuster {
        func describe() -> String
        func adjust(_ item: BatchedWitnessForecast, value: Double) -> Double
    }

    final class FlaggedBatchedWitnessForecastAdjuster: BatchedWitnessForecastAdjuster {
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

        func adjust(_ item: BatchedWitnessForecast, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleBatchedWitnessForecastAdjuster: BatchedWitnessForecastAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: BatchedWitnessForecast, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredBatchedWitnessForecastAdjuster: BatchedWitnessForecastAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedWitnessForecast, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumBatchedWitnessForecastAdjuster: BatchedWitnessForecastAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedWitnessForecast, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the batched witness forecast steps in order and keeps a trace of each.
    final class BatchedWitnessForecastEngine {
        var steps: [any BatchedWitnessForecastAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedWitnessForecastAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: BatchedWitnessForecast) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedWitnessForecastAdjuster = steps[index]
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

        func evaluateAll(_ items: [BatchedWitnessForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultBatchedWitnessForecastEngine(_ flags: Kit.Flags.Registry) -> BatchedWitnessForecastEngine {
        return BatchedWitnessForecastEngine(
            steps: [
                FlaggedBatchedWitnessForecastAdjuster(
                    flags: flags,
                    flag: "batched-witness-forecast-primary",
                    percent: 8.1
                ),
                TitleBatchedWitnessForecastAdjuster(factors: ["north": 0.94]),
                TieredBatchedWitnessForecastAdjuster(bounds: [2472.0, 4406.0, 7356.0], rates: [0.9, 0.86, 1.13]),
                MinimumBatchedWitnessForecastAdjuster(minimum: 49.1),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 31188.4
        )
    }
}
