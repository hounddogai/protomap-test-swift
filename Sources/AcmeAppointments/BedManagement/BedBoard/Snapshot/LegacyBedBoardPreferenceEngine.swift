import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the legacy bed board preference calculation.
    protocol LegacyBedBoardPreferenceStep {
        func describe() -> String
        func adjust(_ item: LegacyBedBoardPreference, value: Double) -> Double
    }

    final class FlaggedLegacyBedBoardPreferenceAdjuster: LegacyBedBoardPreferenceStep {
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

        func adjust(_ item: LegacyBedBoardPreference, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentLegacyBedBoardPreferenceAdjuster: LegacyBedBoardPreferenceStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LegacyBedBoardPreference, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LegacyBedBoardPreferenceCostOffsetAdjuster: LegacyBedBoardPreferenceStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: LegacyBedBoardPreference, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    final class TieredLegacyBedBoardPreferenceAdjuster: LegacyBedBoardPreferenceStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyBedBoardPreference, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingLegacyBedBoardPreferenceAdjuster: LegacyBedBoardPreferenceStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyBedBoardPreference, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapLegacyBedBoardPreferenceAdjuster: LegacyBedBoardPreferenceStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyBedBoardPreference, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the legacy bed board preference steps in order and keeps a trace of each.
    final class LegacyBedBoardPreferenceEngine {
        var steps: [any LegacyBedBoardPreferenceStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyBedBoardPreferenceStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LegacyBedBoardPreference) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyBedBoardPreferenceStep = steps[index]
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

        func evaluateAll(_ items: [LegacyBedBoardPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLegacyBedBoardPreferenceEngine(_ flags: Kit.Flags.Registry) -> LegacyBedBoardPreferenceEngine {
        return LegacyBedBoardPreferenceEngine(
            steps: [
                FlaggedLegacyBedBoardPreferenceAdjuster(
                    flags: flags,
                    flag: "legacy-bed-board-preference-default",
                    percent: 0.1
                ),
                PercentLegacyBedBoardPreferenceAdjuster(percent: -11.8),
                LegacyBedBoardPreferenceCostOffsetAdjuster(weight: 0.07),
                TieredLegacyBedBoardPreferenceAdjuster(
                    bounds: [153.0, 542.0, 1619.0, 1712.0],
                    rates: [1.0, 0.95, 1.04, 1.03]
                ),
                RoundingLegacyBedBoardPreferenceAdjuster(step: 0.05),
                CapLegacyBedBoardPreferenceAdjuster(cap: 9047.0),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 39508.9
        )
    }
}
