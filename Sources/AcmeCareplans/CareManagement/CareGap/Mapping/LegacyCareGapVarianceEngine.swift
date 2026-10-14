import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the legacy care gap variance calculation.
    protocol LegacyCareGapVarianceAdjuster {
        func describe() -> String
        func adjust(_ item: LegacyCareGapVariance, value: Double) -> Double
    }

    final class RoundingLegacyCareGapVarianceAdjuster: LegacyCareGapVarianceAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyCareGapVariance, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredLegacyCareGapVarianceAdjuster: LegacyCareGapVarianceAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyCareGapVariance, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedLegacyCareGapVarianceAdjuster: LegacyCareGapVarianceAdjuster {
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

        func adjust(_ item: LegacyCareGapVariance, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumLegacyCareGapVarianceAdjuster: LegacyCareGapVarianceAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyCareGapVariance, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the legacy care gap variance steps in order and keeps a trace of each.
    final class LegacyCareGapVarianceEngine {
        var steps: [any LegacyCareGapVarianceAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyCareGapVarianceAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LegacyCareGapVariance) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [LegacyCareGapVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLegacyCareGapVarianceEngine(_ flags: Kit.Flags.Registry) -> LegacyCareGapVarianceEngine {
        return LegacyCareGapVarianceEngine(
            steps: [
                RoundingLegacyCareGapVarianceAdjuster(step: 0.1),
                TieredLegacyCareGapVarianceAdjuster(bounds: [955.0, 2083.0], rates: [0.87, 0.8]),
                FlaggedLegacyCareGapVarianceAdjuster(
                    flags: flags,
                    flag: "legacy-care-gap-variance-strict",
                    percent: 7.1
                ),
                MinimumLegacyCareGapVarianceAdjuster(minimum: 15.1),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 3063.8
        )
    }
}
