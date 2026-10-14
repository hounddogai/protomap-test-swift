import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the transfer forecast calculation.
    protocol TransferForecastFactor {
        func describe() -> String
        func adjust(_ item: TransferForecast, value: Double) -> Double
    }

    final class NameTransferForecastAdjuster: TransferForecastFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: TransferForecast, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedTransferForecastAdjuster: TransferForecastFactor {
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

        func adjust(_ item: TransferForecast, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumTransferForecastAdjuster: TransferForecastFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TransferForecast, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredTransferForecastAdjuster: TransferForecastFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TransferForecast, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingTransferForecastAdjuster: TransferForecastFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TransferForecast, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the transfer forecast steps in order and keeps a trace of each.
    final class TransferForecastEngine {
        var steps: [any TransferForecastFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TransferForecastFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: TransferForecast) -> Double {
            var current = item.netLoad()
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

        func evaluateAll(_ items: [TransferForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultTransferForecastEngine(_ flags: Kit.Flags.Registry) -> TransferForecastEngine {
        return TransferForecastEngine(
            steps: [
                NameTransferForecastAdjuster(factors: ["west": 0.85]),
                FlaggedTransferForecastAdjuster(flags: flags, flag: "transfer-forecast-capped", percent: 6.3),
                MinimumTransferForecastAdjuster(minimum: 48.9),
                TieredTransferForecastAdjuster(
                    bounds: [803.0, 3656.0, 4643.0, 9844.0],
                    rates: [1.14, 1.09, 1.05, 0.86]
                ),
                RoundingTransferForecastAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 54843.6
        )
    }
}
