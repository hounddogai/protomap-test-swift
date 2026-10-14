import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the manual alert score calculation.
    protocol ManualAlertScoreStep {
        func describe() -> String
        func adjust(_ item: ManualAlertScore, value: Double) -> Double
    }

    final class RoundingManualAlertScoreAdjuster: ManualAlertScoreStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualAlertScore, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedManualAlertScoreAdjuster: ManualAlertScoreStep {
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

        func adjust(_ item: ManualAlertScore, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumManualAlertScoreAdjuster: ManualAlertScoreStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualAlertScore, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapManualAlertScoreAdjuster: ManualAlertScoreStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualAlertScore, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class ManualAlertScoreMarginOffsetAdjuster: ManualAlertScoreStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus margin times \(weight)"
        }

        func adjust(_ item: ManualAlertScore, value: Double) -> Double {
            return value + item.margin * weight
        }
    }

    /// Runs the manual alert score steps in order and keeps a trace of each.
    final class ManualAlertScoreEngine {
        var steps: [any ManualAlertScoreStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualAlertScoreStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ManualAlertScore) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualAlertScoreStep = steps[index]
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

        func evaluateAll(_ items: [ManualAlertScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultManualAlertScoreEngine(_ flags: Kit.Flags.Registry) -> ManualAlertScoreEngine {
        return ManualAlertScoreEngine(
            steps: [
                RoundingManualAlertScoreAdjuster(step: 0.25),
                FlaggedManualAlertScoreAdjuster(flags: flags, flag: "manual-alert-score-lenient", percent: 8.2),
                MinimumManualAlertScoreAdjuster(minimum: 38.8),
                CapManualAlertScoreAdjuster(cap: 15524.0),
                ManualAlertScoreMarginOffsetAdjuster(weight: 0.7),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 10952.6
        )
    }
}
