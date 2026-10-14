import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the overtime rollup calculation.
    protocol OvertimeRollupFactor {
        func describe() -> String
        func adjust(_ item: OvertimeRollup, value: Double) -> Double
    }

    final class FlaggedOvertimeRollupAdjuster: OvertimeRollupFactor {
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

        func adjust(_ item: OvertimeRollup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumOvertimeRollupAdjuster: OvertimeRollupFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: OvertimeRollup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingOvertimeRollupAdjuster: OvertimeRollupFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: OvertimeRollup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the overtime rollup steps in order and keeps a trace of each.
    final class OvertimeRollupEngine {
        var steps: [any OvertimeRollupFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OvertimeRollupFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: OvertimeRollup) -> Double {
            var current = item.adjustedValue()
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

        func evaluateAll(_ items: [OvertimeRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultOvertimeRollupEngine(_ flags: Kit.Flags.Registry) -> OvertimeRollupEngine {
        return OvertimeRollupEngine(
            steps: [
                FlaggedOvertimeRollupAdjuster(flags: flags, flag: "overtime-rollup-pending", percent: 3.9),
                MinimumOvertimeRollupAdjuster(minimum: 21.0),
                RoundingOvertimeRollupAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 24413.8
        )
    }
}
