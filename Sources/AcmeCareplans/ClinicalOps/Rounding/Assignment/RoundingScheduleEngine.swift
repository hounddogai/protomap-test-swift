import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the rounding schedule calculation.
    protocol RoundingScheduleStep {
        func describe() -> String
        func adjust(_ item: RoundingSchedule, value: Double) -> Double
    }

    final class CapRoundingScheduleAdjuster: RoundingScheduleStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RoundingSchedule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingRoundingScheduleAdjuster: RoundingScheduleStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RoundingSchedule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedRoundingScheduleAdjuster: RoundingScheduleStep {
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

        func adjust(_ item: RoundingSchedule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the rounding schedule steps in order and keeps a trace of each.
    final class RoundingScheduleEngine {
        var steps: [any RoundingScheduleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RoundingScheduleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RoundingSchedule) -> Double {
            var current = item.weightedVolume()
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

        func evaluateAll(_ items: [RoundingSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRoundingScheduleEngine(_ flags: Kit.Flags.Registry) -> RoundingScheduleEngine {
        return RoundingScheduleEngine(
            steps: [
                CapRoundingScheduleAdjuster(cap: 45446.0),
                RoundingRoundingScheduleAdjuster(step: 5.0),
                FlaggedRoundingScheduleAdjuster(flags: flags, flag: "rounding-schedule-capped", percent: 3.8),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 29061.0
        )
    }
}
