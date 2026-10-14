import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the seasonal remittance policy calculation.
    protocol SeasonalRemittancePolicyStep {
        func describe() -> String
        func adjust(_ item: SeasonalRemittancePolicy, value: Double) -> Double
    }

    final class RoundingSeasonalRemittancePolicyAdjuster: SeasonalRemittancePolicyStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalRemittancePolicy, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TitleSeasonalRemittancePolicyAdjuster: SeasonalRemittancePolicyStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: SeasonalRemittancePolicy, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class SeasonalRemittancePolicyRatioOffsetAdjuster: SeasonalRemittancePolicyStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: SeasonalRemittancePolicy, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    final class FlaggedSeasonalRemittancePolicyAdjuster: SeasonalRemittancePolicyStep {
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

        func adjust(_ item: SeasonalRemittancePolicy, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumSeasonalRemittancePolicyAdjuster: SeasonalRemittancePolicyStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalRemittancePolicy, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredSeasonalRemittancePolicyAdjuster: SeasonalRemittancePolicyStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalRemittancePolicy, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the seasonal remittance policy steps in order and keeps a trace of each.
    final class SeasonalRemittancePolicyEngine {
        var steps: [any SeasonalRemittancePolicyStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalRemittancePolicyStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: SeasonalRemittancePolicy) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalRemittancePolicyStep = steps[index]
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

        func evaluateAll(_ items: [SeasonalRemittancePolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultSeasonalRemittancePolicyEngine(_ flags: Kit.Flags.Registry) -> SeasonalRemittancePolicyEngine {
        return SeasonalRemittancePolicyEngine(
            steps: [
                RoundingSeasonalRemittancePolicyAdjuster(step: 0.1),
                TitleSeasonalRemittancePolicyAdjuster(factors: ["retail": 1.37, "east": 1.02, "north": 0.96]),
                SeasonalRemittancePolicyRatioOffsetAdjuster(weight: 0.65),
                FlaggedSeasonalRemittancePolicyAdjuster(
                    flags: flags,
                    flag: "seasonal-remittance-policy-primary",
                    percent: 8.7
                ),
                MinimumSeasonalRemittancePolicyAdjuster(minimum: 4.5),
                TieredSeasonalRemittancePolicyAdjuster(
                    bounds: [3078.0, 3091.0, 3498.0, 4457.0],
                    rates: [1.1, 0.84, 1.03, 1.15]
                ),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 36122.7
        )
    }
}
