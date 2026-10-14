import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the capped rounding schedule calculation.
    protocol CappedRoundingScheduleAdjuster {
        func describe() -> String
        func adjust(_ item: CappedRoundingSchedule, value: Double) -> Double
    }

    final class CapCappedRoundingScheduleAdjuster: CappedRoundingScheduleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedRoundingSchedule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumCappedRoundingScheduleAdjuster: CappedRoundingScheduleAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedRoundingSchedule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedCappedRoundingScheduleAdjuster: CappedRoundingScheduleAdjuster {
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

        func adjust(_ item: CappedRoundingSchedule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the capped rounding schedule steps in order and keeps a trace of each.
    final class CappedRoundingScheduleEngine {
        var steps: [any CappedRoundingScheduleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedRoundingScheduleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CappedRoundingSchedule) -> Double {
            var current = item.projectedValue()
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

        func evaluateAll(_ items: [CappedRoundingSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCappedRoundingScheduleEngine(_ flags: Kit.Flags.Registry) -> CappedRoundingScheduleEngine {
        return CappedRoundingScheduleEngine(
            steps: [
                CapCappedRoundingScheduleAdjuster(cap: 3270.0),
                MinimumCappedRoundingScheduleAdjuster(minimum: 23.6),
                FlaggedCappedRoundingScheduleAdjuster(
                    flags: flags,
                    flag: "capped-rounding-schedule-adaptive",
                    percent: -5.6
                ),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 30062.6
        )
    }
}
