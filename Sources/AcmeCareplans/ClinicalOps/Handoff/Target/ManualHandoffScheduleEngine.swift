import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the manual handoff schedule calculation.
    protocol ManualHandoffScheduleAdjuster {
        func describe() -> String
        func adjust(_ item: ManualHandoffSchedule, value: Double) -> Double
    }

    final class ManualHandoffScheduleUpdatedAtOffsetAdjuster: ManualHandoffScheduleAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: ManualHandoffSchedule, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    final class FlaggedManualHandoffScheduleAdjuster: ManualHandoffScheduleAdjuster {
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

        func adjust(_ item: ManualHandoffSchedule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelManualHandoffScheduleAdjuster: ManualHandoffScheduleAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: ManualHandoffSchedule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentManualHandoffScheduleAdjuster: ManualHandoffScheduleAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualHandoffSchedule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the manual handoff schedule steps in order and keeps a trace of each.
    final class ManualHandoffScheduleEngine {
        var steps: [any ManualHandoffScheduleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualHandoffScheduleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ManualHandoffSchedule) -> Double {
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

        func evaluateAll(_ items: [ManualHandoffSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultManualHandoffScheduleEngine(_ flags: Kit.Flags.Registry) -> ManualHandoffScheduleEngine {
        return ManualHandoffScheduleEngine(
            steps: [
                ManualHandoffScheduleUpdatedAtOffsetAdjuster(weight: 0.12),
                FlaggedManualHandoffScheduleAdjuster(
                    flags: flags,
                    flag: "manual-handoff-schedule-pending",
                    percent: -7.8
                ),
                LabelManualHandoffScheduleAdjuster(factors: ["online": 1.24, "north": 0.98, "south": 0.72]),
                PercentManualHandoffScheduleAdjuster(percent: 17.0),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 61154.3
        )
    }
}
