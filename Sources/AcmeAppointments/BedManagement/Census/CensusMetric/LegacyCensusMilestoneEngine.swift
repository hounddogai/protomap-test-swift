import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the legacy census milestone calculation.
    protocol LegacyCensusMilestoneStep {
        func describe() -> String
        func adjust(_ item: LegacyCensusMilestone, value: Double) -> Double
    }

    final class TieredLegacyCensusMilestoneAdjuster: LegacyCensusMilestoneStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyCensusMilestone, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumLegacyCensusMilestoneAdjuster: LegacyCensusMilestoneStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyCensusMilestone, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapLegacyCensusMilestoneAdjuster: LegacyCensusMilestoneStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyCensusMilestone, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LegacyCensusMilestoneStartsAtOffsetAdjuster: LegacyCensusMilestoneStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: LegacyCensusMilestone, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    final class FlaggedLegacyCensusMilestoneAdjuster: LegacyCensusMilestoneStep {
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

        func adjust(_ item: LegacyCensusMilestone, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the legacy census milestone steps in order and keeps a trace of each.
    final class LegacyCensusMilestoneEngine {
        var steps: [any LegacyCensusMilestoneStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyCensusMilestoneStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LegacyCensusMilestone) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyCensusMilestoneStep = steps[index]
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

        func evaluateAll(_ items: [LegacyCensusMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLegacyCensusMilestoneEngine(_ flags: Kit.Flags.Registry) -> LegacyCensusMilestoneEngine {
        return LegacyCensusMilestoneEngine(
            steps: [
                TieredLegacyCensusMilestoneAdjuster(bounds: [2888.0, 3245.0], rates: [1.12, 1.17]),
                MinimumLegacyCensusMilestoneAdjuster(minimum: 31.2),
                CapLegacyCensusMilestoneAdjuster(cap: 24326.0),
                LegacyCensusMilestoneStartsAtOffsetAdjuster(weight: 1.9),
                FlaggedLegacyCensusMilestoneAdjuster(
                    flags: flags,
                    flag: "legacy-census-milestone-lenient",
                    percent: -4.8
                ),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 69440.1
        )
    }
}
