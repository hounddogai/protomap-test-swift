import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the strict transfer forecast calculation.
    protocol StrictTransferForecastAdjuster {
        func describe() -> String
        func adjust(_ item: StrictTransferForecast, value: Double) -> Double
    }

    final class StrictTransferForecastCapacityOffsetAdjuster: StrictTransferForecastAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: StrictTransferForecast, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    final class LabelStrictTransferForecastAdjuster: StrictTransferForecastAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: StrictTransferForecast, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredStrictTransferForecastAdjuster: StrictTransferForecastAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictTransferForecast, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentStrictTransferForecastAdjuster: StrictTransferForecastAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictTransferForecast, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumStrictTransferForecastAdjuster: StrictTransferForecastAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictTransferForecast, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedStrictTransferForecastAdjuster: StrictTransferForecastAdjuster {
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

        func adjust(_ item: StrictTransferForecast, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the strict transfer forecast steps in order and keeps a trace of each.
    final class StrictTransferForecastEngine {
        var steps: [any StrictTransferForecastAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictTransferForecastAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: StrictTransferForecast) -> Double {
            var current = item.weightedLoad()
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

        func evaluateAll(_ items: [StrictTransferForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultStrictTransferForecastEngine(_ flags: Kit.Flags.Registry) -> StrictTransferForecastEngine {
        return StrictTransferForecastEngine(
            steps: [
                StrictTransferForecastCapacityOffsetAdjuster(weight: 0.97),
                LabelStrictTransferForecastAdjuster(factors: ["south": 1.22, "central": 0.97, "online": 0.72]),
                TieredStrictTransferForecastAdjuster(bounds: [4134.0, 8258.0, 9968.0], rates: [1.04, 1.05, 1.16]),
                PercentStrictTransferForecastAdjuster(percent: 1.0),
                MinimumStrictTransferForecastAdjuster(minimum: 12.1),
                FlaggedStrictTransferForecastAdjuster(
                    flags: flags,
                    flag: "strict-transfer-forecast-strict",
                    percent: 8.9
                ),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 21319.0
        )
    }
}
