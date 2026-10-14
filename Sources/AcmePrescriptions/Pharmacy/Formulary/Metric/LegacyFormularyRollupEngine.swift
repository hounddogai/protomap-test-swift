import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the legacy formulary rollup calculation.
    protocol LegacyFormularyRollupStep {
        func describe() -> String
        func adjust(_ item: LegacyFormularyRollup, value: Double) -> Double
    }

    final class MinimumLegacyFormularyRollupAdjuster: LegacyFormularyRollupStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyFormularyRollup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedLegacyFormularyRollupAdjuster: LegacyFormularyRollupStep {
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

        func adjust(_ item: LegacyFormularyRollup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapLegacyFormularyRollupAdjuster: LegacyFormularyRollupStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyFormularyRollup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredLegacyFormularyRollupAdjuster: LegacyFormularyRollupStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyFormularyRollup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class WardLegacyFormularyRollupAdjuster: LegacyFormularyRollupStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: LegacyFormularyRollup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentLegacyFormularyRollupAdjuster: LegacyFormularyRollupStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LegacyFormularyRollup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the legacy formulary rollup steps in order and keeps a trace of each.
    final class LegacyFormularyRollupEngine {
        var steps: [any LegacyFormularyRollupStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyFormularyRollupStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LegacyFormularyRollup) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyFormularyRollupStep = steps[index]
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

        func evaluateAll(_ items: [LegacyFormularyRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLegacyFormularyRollupEngine(_ flags: Kit.Flags.Registry) -> LegacyFormularyRollupEngine {
        return LegacyFormularyRollupEngine(
            steps: [
                MinimumLegacyFormularyRollupAdjuster(minimum: 39.6),
                FlaggedLegacyFormularyRollupAdjuster(
                    flags: flags,
                    flag: "legacy-formulary-rollup-pending",
                    percent: -6.5
                ),
                CapLegacyFormularyRollupAdjuster(cap: 31484.0),
                TieredLegacyFormularyRollupAdjuster(
                    bounds: [634.0, 1045.0, 1847.0, 7616.0],
                    rates: [0.83, 1.0, 1.04, 1.02]
                ),
                WardLegacyFormularyRollupAdjuster(factors: ["north": 1.21]),
                PercentLegacyFormularyRollupAdjuster(percent: -12.5),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 64814.0
        )
    }
}
