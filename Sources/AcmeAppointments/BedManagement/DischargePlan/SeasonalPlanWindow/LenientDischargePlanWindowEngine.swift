import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the lenient discharge plan window calculation.
    protocol LenientDischargePlanWindowModifier {
        func describe() -> String
        func adjust(_ item: LenientDischargePlanWindow, value: Double) -> Double
    }

    final class FlaggedLenientDischargePlanWindowAdjuster: LenientDischargePlanWindowModifier {
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

        func adjust(_ item: LenientDischargePlanWindow, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingLenientDischargePlanWindowAdjuster: LenientDischargePlanWindowModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientDischargePlanWindow, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapLenientDischargePlanWindowAdjuster: LenientDischargePlanWindowModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientDischargePlanWindow, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LenientDischargePlanWindowThresholdOffsetAdjuster: LenientDischargePlanWindowModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: LenientDischargePlanWindow, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    /// Runs the lenient discharge plan window steps in order and keeps a trace of each.
    final class LenientDischargePlanWindowEngine {
        var steps: [any LenientDischargePlanWindowModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientDischargePlanWindowModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LenientDischargePlanWindow) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientDischargePlanWindowModifier = steps[index]
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

        func evaluateAll(_ items: [LenientDischargePlanWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLenientDischargePlanWindowEngine(_ flags: Kit.Flags.Registry) -> LenientDischargePlanWindowEngine {
        return LenientDischargePlanWindowEngine(
            steps: [
                FlaggedLenientDischargePlanWindowAdjuster(
                    flags: flags,
                    flag: "lenient-discharge-plan-window-capped",
                    percent: -8.2
                ),
                RoundingLenientDischargePlanWindowAdjuster(step: 5.0),
                CapLenientDischargePlanWindowAdjuster(cap: 563.0),
                LenientDischargePlanWindowThresholdOffsetAdjuster(weight: 0.29),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 78613.2
        )
    }
}
