import AcmePlatform
import Foundation

extension Labs {
    /// One step of the legacy accession schedule calculation.
    protocol LegacyAccessionScheduleStep {
        func describe() -> String
        func adjust(_ item: LegacyAccessionSchedule, value: Double) -> Double
    }

    final class FlaggedLegacyAccessionScheduleAdjuster: LegacyAccessionScheduleStep {
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

        func adjust(_ item: LegacyAccessionSchedule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapLegacyAccessionScheduleAdjuster: LegacyAccessionScheduleStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyAccessionSchedule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumLegacyAccessionScheduleAdjuster: LegacyAccessionScheduleStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyAccessionSchedule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the legacy accession schedule steps in order and keeps a trace of each.
    final class LegacyAccessionScheduleEngine {
        var steps: [any LegacyAccessionScheduleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyAccessionScheduleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LegacyAccessionSchedule) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyAccessionScheduleStep = steps[index]
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

        func evaluateAll(_ items: [LegacyAccessionSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLegacyAccessionScheduleEngine(_ flags: Kit.Flags.Registry) -> LegacyAccessionScheduleEngine {
        return LegacyAccessionScheduleEngine(
            steps: [
                FlaggedLegacyAccessionScheduleAdjuster(
                    flags: flags,
                    flag: "legacy-accession-schedule-fallback",
                    percent: -2.1
                ),
                CapLegacyAccessionScheduleAdjuster(cap: 44558.0),
                MinimumLegacyAccessionScheduleAdjuster(minimum: 21.3),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 29071.6
        )
    }
}
