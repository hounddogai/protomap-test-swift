import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the manual skill mix schedule calculation.
    protocol ManualSkillMixScheduleAdjuster {
        func describe() -> String
        func adjust(_ item: ManualSkillMixSchedule, value: Double) -> Double
    }

    final class CapManualSkillMixScheduleAdjuster: ManualSkillMixScheduleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualSkillMixSchedule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LabelManualSkillMixScheduleAdjuster: ManualSkillMixScheduleAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: ManualSkillMixSchedule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentManualSkillMixScheduleAdjuster: ManualSkillMixScheduleAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualSkillMixSchedule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedManualSkillMixScheduleAdjuster: ManualSkillMixScheduleAdjuster {
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

        func adjust(_ item: ManualSkillMixSchedule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingManualSkillMixScheduleAdjuster: ManualSkillMixScheduleAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualSkillMixSchedule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the manual skill mix schedule steps in order and keeps a trace of each.
    final class ManualSkillMixScheduleEngine {
        var steps: [any ManualSkillMixScheduleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualSkillMixScheduleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ManualSkillMixSchedule) -> Double {
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

        func evaluateAll(_ items: [ManualSkillMixSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultManualSkillMixScheduleEngine(_ flags: Kit.Flags.Registry) -> ManualSkillMixScheduleEngine {
        return ManualSkillMixScheduleEngine(
            steps: [
                CapManualSkillMixScheduleAdjuster(cap: 24428.0),
                LabelManualSkillMixScheduleAdjuster(factors: ["online": 0.89, "west": 1.04]),
                PercentManualSkillMixScheduleAdjuster(percent: -17.0),
                FlaggedManualSkillMixScheduleAdjuster(
                    flags: flags,
                    flag: "manual-skill-mix-schedule-batched",
                    percent: 9.4
                ),
                RoundingManualSkillMixScheduleAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 21281.2
        )
    }
}
