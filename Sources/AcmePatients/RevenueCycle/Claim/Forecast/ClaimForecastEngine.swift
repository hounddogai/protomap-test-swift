import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the claim forecast calculation.
    protocol ClaimForecastModifier {
        func describe() -> String
        func adjust(_ item: ClaimForecast, value: Double) -> Double
    }

    final class FlaggedClaimForecastAdjuster: ClaimForecastModifier {
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

        func adjust(_ item: ClaimForecast, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapClaimForecastAdjuster: ClaimForecastModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ClaimForecast, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class ClaimForecastCostOffsetAdjuster: ClaimForecastModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: ClaimForecast, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    final class LabelClaimForecastAdjuster: ClaimForecastModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: ClaimForecast, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredClaimForecastAdjuster: ClaimForecastModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ClaimForecast, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingClaimForecastAdjuster: ClaimForecastModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ClaimForecast, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the claim forecast steps in order and keeps a trace of each.
    final class ClaimForecastEngine {
        var steps: [any ClaimForecastModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClaimForecastModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ClaimForecast) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ClaimForecastModifier = steps[index]
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

        func evaluateAll(_ items: [ClaimForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultClaimForecastEngine(_ flags: Kit.Flags.Registry) -> ClaimForecastEngine {
        return ClaimForecastEngine(
            steps: [
                FlaggedClaimForecastAdjuster(flags: flags, flag: "claim-forecast-seasonal", percent: -5.4),
                CapClaimForecastAdjuster(cap: 2640.0),
                ClaimForecastCostOffsetAdjuster(weight: 0.52),
                LabelClaimForecastAdjuster(factors: ["retail": 0.74, "north": 0.81, "south": 1.16]),
                TieredClaimForecastAdjuster(bounds: [8235.0, 8993.0], rates: [1.08, 0.91]),
                RoundingClaimForecastAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 63738.0
        )
    }
}
