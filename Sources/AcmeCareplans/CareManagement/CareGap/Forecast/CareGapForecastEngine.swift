import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the care gap forecast calculation.
    protocol CareGapForecastAdjuster {
        func describe() -> String
        func adjust(_ item: CareGapForecast, value: Double) -> Double
    }

    final class NameCareGapForecastAdjuster: CareGapForecastAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: CareGapForecast, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapCareGapForecastAdjuster: CareGapForecastAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CareGapForecast, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedCareGapForecastAdjuster: CareGapForecastAdjuster {
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

        func adjust(_ item: CareGapForecast, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CareGapForecastFloorValueOffsetAdjuster: CareGapForecastAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus floor value times \(weight)"
        }

        func adjust(_ item: CareGapForecast, value: Double) -> Double {
            return value + item.floorValue * weight
        }
    }

    final class PercentCareGapForecastAdjuster: CareGapForecastAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CareGapForecast, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredCareGapForecastAdjuster: CareGapForecastAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CareGapForecast, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the care gap forecast steps in order and keeps a trace of each.
    final class CareGapForecastEngine {
        var steps: [any CareGapForecastAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareGapForecastAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CareGapForecast) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any CareGapForecastAdjuster = steps[index]
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

        func evaluateAll(_ items: [CareGapForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCareGapForecastEngine(_ flags: Kit.Flags.Registry) -> CareGapForecastEngine {
        return CareGapForecastEngine(
            steps: [
                NameCareGapForecastAdjuster(factors: ["central": 0.76, "retail": 0.87, "west": 0.73]),
                CapCareGapForecastAdjuster(cap: 37676.0),
                FlaggedCareGapForecastAdjuster(flags: flags, flag: "care-gap-forecast-tiered", percent: -0.0),
                CareGapForecastFloorValueOffsetAdjuster(weight: 1.2),
                PercentCareGapForecastAdjuster(percent: -15.4),
                TieredCareGapForecastAdjuster(bounds: [3528.0, 3921.0, 6217.0], rates: [0.93, 0.85, 0.98]),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 25132.6
        )
    }
}
