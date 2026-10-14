import AcmePlatform
import Foundation

extension Consent {
    /// One step of the fallback language plan calculation.
    protocol FallbackLanguagePlanStep {
        func describe() -> String
        func adjust(_ item: FallbackLanguagePlan, value: Double) -> Double
    }

    final class PercentFallbackLanguagePlanAdjuster: FallbackLanguagePlanStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackLanguagePlan, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingFallbackLanguagePlanAdjuster: FallbackLanguagePlanStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackLanguagePlan, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredFallbackLanguagePlanAdjuster: FallbackLanguagePlanStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackLanguagePlan, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedFallbackLanguagePlanAdjuster: FallbackLanguagePlanStep {
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

        func adjust(_ item: FallbackLanguagePlan, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumFallbackLanguagePlanAdjuster: FallbackLanguagePlanStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackLanguagePlan, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FallbackLanguagePlanRatioOffsetAdjuster: FallbackLanguagePlanStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: FallbackLanguagePlan, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    /// Runs the fallback language plan steps in order and keeps a trace of each.
    final class FallbackLanguagePlanEngine {
        var steps: [any FallbackLanguagePlanStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackLanguagePlanStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: FallbackLanguagePlan) -> Double {
            var current = item.projectedLoad()
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

        func evaluateAll(_ items: [FallbackLanguagePlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultFallbackLanguagePlanEngine(_ flags: Kit.Flags.Registry) -> FallbackLanguagePlanEngine {
        return FallbackLanguagePlanEngine(
            steps: [
                PercentFallbackLanguagePlanAdjuster(percent: 20.0),
                RoundingFallbackLanguagePlanAdjuster(step: 0.25),
                TieredFallbackLanguagePlanAdjuster(
                    bounds: [649.0, 880.0, 5556.0, 7159.0],
                    rates: [0.92, 1.08, 0.84, 1.13]
                ),
                FlaggedFallbackLanguagePlanAdjuster(
                    flags: flags,
                    flag: "fallback-language-plan-rolling",
                    percent: -1.2
                ),
                MinimumFallbackLanguagePlanAdjuster(minimum: 25.2),
                FallbackLanguagePlanRatioOffsetAdjuster(weight: 0.16),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 96291.7
        )
    }
}
