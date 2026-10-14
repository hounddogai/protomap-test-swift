import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the shift target calculation.
    protocol ShiftTargetFactor {
        func describe() -> String
        func adjust(_ item: ShiftTarget, value: Double) -> Double
    }

    final class FlaggedShiftTargetAdjuster: ShiftTargetFactor {
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

        func adjust(_ item: ShiftTarget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapShiftTargetAdjuster: ShiftTargetFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ShiftTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumShiftTargetAdjuster: ShiftTargetFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ShiftTarget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingShiftTargetAdjuster: ShiftTargetFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ShiftTarget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the shift target steps in order and keeps a trace of each.
    final class ShiftTargetEngine {
        var steps: [any ShiftTargetFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ShiftTargetFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ShiftTarget) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any ShiftTargetFactor = steps[index]
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

        func evaluateAll(_ items: [ShiftTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultShiftTargetEngine(_ flags: Kit.Flags.Registry) -> ShiftTargetEngine {
        return ShiftTargetEngine(
            steps: [
                FlaggedShiftTargetAdjuster(flags: flags, flag: "shift-target-seasonal", percent: 1.0),
                CapShiftTargetAdjuster(cap: 17366.0),
                MinimumShiftTargetAdjuster(minimum: 40.1),
                RoundingShiftTargetAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 57178.6
        )
    }
}
