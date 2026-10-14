import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the rolling inventory schedule calculation.
    protocol RollingInventoryScheduleStep {
        func describe() -> String
        func adjust(_ item: RollingInventorySchedule, value: Double) -> Double
    }

    final class RegionRollingInventoryScheduleAdjuster: RollingInventoryScheduleStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: RollingInventorySchedule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentRollingInventoryScheduleAdjuster: RollingInventoryScheduleStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingInventorySchedule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedRollingInventoryScheduleAdjuster: RollingInventoryScheduleStep {
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

        func adjust(_ item: RollingInventorySchedule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingRollingInventoryScheduleAdjuster: RollingInventoryScheduleStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingInventorySchedule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the rolling inventory schedule steps in order and keeps a trace of each.
    final class RollingInventoryScheduleEngine {
        var steps: [any RollingInventoryScheduleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingInventoryScheduleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RollingInventorySchedule) -> Double {
            var current = item.weightedTotal()
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

        func evaluateAll(_ items: [RollingInventorySchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRollingInventoryScheduleEngine(_ flags: Kit.Flags.Registry) -> RollingInventoryScheduleEngine {
        return RollingInventoryScheduleEngine(
            steps: [
                RegionRollingInventoryScheduleAdjuster(factors: ["online": 0.97, "west": 0.8]),
                PercentRollingInventoryScheduleAdjuster(percent: 19.3),
                FlaggedRollingInventoryScheduleAdjuster(
                    flags: flags,
                    flag: "rolling-inventory-schedule-seasonal",
                    percent: -8.5
                ),
                RoundingRollingInventoryScheduleAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 55496.1
        )
    }
}
