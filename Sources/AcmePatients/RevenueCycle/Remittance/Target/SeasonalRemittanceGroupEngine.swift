import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the seasonal remittance group calculation.
    protocol SeasonalRemittanceGroupAdjuster {
        func describe() -> String
        func adjust(_ item: SeasonalRemittanceGroup, value: Double) -> Double
    }

    final class LabelSeasonalRemittanceGroupAdjuster: SeasonalRemittanceGroupAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: SeasonalRemittanceGroup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumSeasonalRemittanceGroupAdjuster: SeasonalRemittanceGroupAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalRemittanceGroup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedSeasonalRemittanceGroupAdjuster: SeasonalRemittanceGroupAdjuster {
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

        func adjust(_ item: SeasonalRemittanceGroup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentSeasonalRemittanceGroupAdjuster: SeasonalRemittanceGroupAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalRemittanceGroup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapSeasonalRemittanceGroupAdjuster: SeasonalRemittanceGroupAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalRemittanceGroup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingSeasonalRemittanceGroupAdjuster: SeasonalRemittanceGroupAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalRemittanceGroup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the seasonal remittance group steps in order and keeps a trace of each.
    final class SeasonalRemittanceGroupEngine {
        var steps: [any SeasonalRemittanceGroupAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalRemittanceGroupAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SeasonalRemittanceGroup) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalRemittanceGroupAdjuster = steps[index]
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

        func evaluateAll(_ items: [SeasonalRemittanceGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSeasonalRemittanceGroupEngine(_ flags: Kit.Flags.Registry) -> SeasonalRemittanceGroupEngine {
        return SeasonalRemittanceGroupEngine(
            steps: [
                LabelSeasonalRemittanceGroupAdjuster(factors: ["west": 1.31]),
                MinimumSeasonalRemittanceGroupAdjuster(minimum: 16.6),
                FlaggedSeasonalRemittanceGroupAdjuster(
                    flags: flags,
                    flag: "seasonal-remittance-group-rolling",
                    percent: 6.3
                ),
                PercentSeasonalRemittanceGroupAdjuster(percent: -5.7),
                CapSeasonalRemittanceGroupAdjuster(cap: 9307.0),
                RoundingSeasonalRemittanceGroupAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 6320.7
        )
    }
}
