import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the legacy shift rollup calculation.
    protocol LegacyShiftRollupFactor {
        func describe() -> String
        func adjust(_ item: LegacyShiftRollup, value: Double) -> Double
    }

    final class MinimumLegacyShiftRollupAdjuster: LegacyShiftRollupFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyShiftRollup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingLegacyShiftRollupAdjuster: LegacyShiftRollupFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyShiftRollup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedLegacyShiftRollupAdjuster: LegacyShiftRollupFactor {
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

        func adjust(_ item: LegacyShiftRollup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RegionLegacyShiftRollupAdjuster: LegacyShiftRollupFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: LegacyShiftRollup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class LegacyShiftRollupScoreOffsetAdjuster: LegacyShiftRollupFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: LegacyShiftRollup, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    /// Runs the legacy shift rollup steps in order and keeps a trace of each.
    final class LegacyShiftRollupEngine {
        var steps: [any LegacyShiftRollupFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyShiftRollupFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LegacyShiftRollup) -> Double {
            var current = item.weightedExposure()
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

        func evaluateAll(_ items: [LegacyShiftRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLegacyShiftRollupEngine(_ flags: Kit.Flags.Registry) -> LegacyShiftRollupEngine {
        return LegacyShiftRollupEngine(
            steps: [
                MinimumLegacyShiftRollupAdjuster(minimum: 29.1),
                RoundingLegacyShiftRollupAdjuster(step: 0.5),
                FlaggedLegacyShiftRollupAdjuster(flags: flags, flag: "legacy-shift-rollup-default", percent: 7.1),
                RegionLegacyShiftRollupAdjuster(factors: ["north": 1.17, "online": 1.0, "retail": 0.72]),
                LegacyShiftRollupScoreOffsetAdjuster(weight: 1.78),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 76157.6
        )
    }
}
