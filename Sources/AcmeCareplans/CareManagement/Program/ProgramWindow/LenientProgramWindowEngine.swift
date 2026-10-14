import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the lenient program window calculation.
    protocol LenientProgramWindowFactor {
        func describe() -> String
        func adjust(_ item: LenientProgramWindow, value: Double) -> Double
    }

    final class LenientProgramWindowThresholdOffsetAdjuster: LenientProgramWindowFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: LenientProgramWindow, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    final class FlaggedLenientProgramWindowAdjuster: LenientProgramWindowFactor {
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

        func adjust(_ item: LenientProgramWindow, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentLenientProgramWindowAdjuster: LenientProgramWindowFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientProgramWindow, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumLenientProgramWindowAdjuster: LenientProgramWindowFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientProgramWindow, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the lenient program window steps in order and keeps a trace of each.
    final class LenientProgramWindowEngine {
        var steps: [any LenientProgramWindowFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientProgramWindowFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LenientProgramWindow) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientProgramWindowFactor = steps[index]
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

        func evaluateAll(_ items: [LenientProgramWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLenientProgramWindowEngine(_ flags: Kit.Flags.Registry) -> LenientProgramWindowEngine {
        return LenientProgramWindowEngine(
            steps: [
                LenientProgramWindowThresholdOffsetAdjuster(weight: 0.4),
                FlaggedLenientProgramWindowAdjuster(
                    flags: flags,
                    flag: "lenient-program-window-default",
                    percent: -0.1
                ),
                PercentLenientProgramWindowAdjuster(percent: -20.3),
                MinimumLenientProgramWindowAdjuster(minimum: 39.6),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 57842.9
        )
    }
}
