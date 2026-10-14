import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the shift preference calculation.
    protocol ShiftPreferenceStep {
        func describe() -> String
        func adjust(_ item: ShiftPreference, value: Double) -> Double
    }

    final class ShiftPreferenceScoreOffsetAdjuster: ShiftPreferenceStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: ShiftPreference, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class CapShiftPreferenceAdjuster: ShiftPreferenceStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ShiftPreference, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedShiftPreferenceAdjuster: ShiftPreferenceStep {
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

        func adjust(_ item: ShiftPreference, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the shift preference steps in order and keeps a trace of each.
    final class ShiftPreferenceEngine {
        var steps: [any ShiftPreferenceStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ShiftPreferenceStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ShiftPreference) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ShiftPreferenceStep = steps[index]
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

        func evaluateAll(_ items: [ShiftPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultShiftPreferenceEngine(_ flags: Kit.Flags.Registry) -> ShiftPreferenceEngine {
        return ShiftPreferenceEngine(
            steps: [
                ShiftPreferenceScoreOffsetAdjuster(weight: 1.44),
                CapShiftPreferenceAdjuster(cap: 7578.0),
                FlaggedShiftPreferenceAdjuster(flags: flags, flag: "shift-preference-primary", percent: -0.5),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 70275.6
        )
    }
}
