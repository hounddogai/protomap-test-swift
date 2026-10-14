import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the strict skill mix forecast calculation.
    protocol StrictSkillMixForecastFactor {
        func describe() -> String
        func adjust(_ item: StrictSkillMixForecast, value: Double) -> Double
    }

    final class CapStrictSkillMixForecastAdjuster: StrictSkillMixForecastFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictSkillMixForecast, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedStrictSkillMixForecastAdjuster: StrictSkillMixForecastFactor {
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

        func adjust(_ item: StrictSkillMixForecast, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredStrictSkillMixForecastAdjuster: StrictSkillMixForecastFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictSkillMixForecast, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumStrictSkillMixForecastAdjuster: StrictSkillMixForecastFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictSkillMixForecast, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class WardStrictSkillMixForecastAdjuster: StrictSkillMixForecastFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: StrictSkillMixForecast, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the strict skill mix forecast steps in order and keeps a trace of each.
    final class StrictSkillMixForecastEngine {
        var steps: [any StrictSkillMixForecastFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictSkillMixForecastFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: StrictSkillMixForecast) -> Double {
            var current = item.effectiveValue()
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

        func evaluateAll(_ items: [StrictSkillMixForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultStrictSkillMixForecastEngine(_ flags: Kit.Flags.Registry) -> StrictSkillMixForecastEngine {
        return StrictSkillMixForecastEngine(
            steps: [
                CapStrictSkillMixForecastAdjuster(cap: 22323.0),
                FlaggedStrictSkillMixForecastAdjuster(
                    flags: flags,
                    flag: "strict-skill-mix-forecast-manual",
                    percent: 7.8
                ),
                TieredStrictSkillMixForecastAdjuster(bounds: [4054.0, 5924.0], rates: [1.06, 1.18]),
                MinimumStrictSkillMixForecastAdjuster(minimum: 17.4),
                WardStrictSkillMixForecastAdjuster(factors: ["south": 1.09, "east": 0.97, "north": 0.87]),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 15155.2
        )
    }
}
