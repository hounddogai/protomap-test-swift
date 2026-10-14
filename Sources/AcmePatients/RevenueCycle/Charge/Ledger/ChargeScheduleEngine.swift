import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the charge schedule calculation.
    protocol ChargeScheduleFactor {
        func describe() -> String
        func adjust(_ item: ChargeSchedule, value: Double) -> Double
    }

    final class FlaggedChargeScheduleAdjuster: ChargeScheduleFactor {
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

        func adjust(_ item: ChargeSchedule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingChargeScheduleAdjuster: ChargeScheduleFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ChargeSchedule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentChargeScheduleAdjuster: ChargeScheduleFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ChargeSchedule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the charge schedule steps in order and keeps a trace of each.
    final class ChargeScheduleEngine {
        var steps: [any ChargeScheduleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ChargeScheduleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ChargeSchedule) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any ChargeScheduleFactor = steps[index]
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

        func evaluateAll(_ items: [ChargeSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultChargeScheduleEngine(_ flags: Kit.Flags.Registry) -> ChargeScheduleEngine {
        return ChargeScheduleEngine(
            steps: [
                FlaggedChargeScheduleAdjuster(flags: flags, flag: "charge-schedule-fallback", percent: -5.3),
                RoundingChargeScheduleAdjuster(step: 1.0),
                PercentChargeScheduleAdjuster(percent: 16.5),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 44089.1
        )
    }
}
