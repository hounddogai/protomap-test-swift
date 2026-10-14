import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the adaptive assessment threshold calculation.
    protocol AdaptiveAssessmentThresholdFactor {
        func describe() -> String
        func adjust(_ item: AdaptiveAssessmentThreshold, value: Double) -> Double
    }

    final class RoundingAdaptiveAssessmentThresholdAdjuster: AdaptiveAssessmentThresholdFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveAssessmentThreshold, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedAdaptiveAssessmentThresholdAdjuster: AdaptiveAssessmentThresholdFactor {
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

        func adjust(_ item: AdaptiveAssessmentThreshold, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapAdaptiveAssessmentThresholdAdjuster: AdaptiveAssessmentThresholdFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveAssessmentThreshold, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the adaptive assessment threshold steps in order and keeps a trace of each.
    final class AdaptiveAssessmentThresholdEngine {
        var steps: [any AdaptiveAssessmentThresholdFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveAssessmentThresholdFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AdaptiveAssessmentThreshold) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveAssessmentThresholdFactor = steps[index]
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

        func evaluateAll(_ items: [AdaptiveAssessmentThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAdaptiveAssessmentThresholdEngine(_ flags: Kit.Flags.Registry) -> AdaptiveAssessmentThresholdEngine {
        return AdaptiveAssessmentThresholdEngine(
            steps: [
                RoundingAdaptiveAssessmentThresholdAdjuster(step: 0.1),
                FlaggedAdaptiveAssessmentThresholdAdjuster(
                    flags: flags,
                    flag: "adaptive-assessment-threshold-seasonal",
                    percent: -8.2
                ),
                CapAdaptiveAssessmentThresholdAdjuster(cap: 24397.0),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 19885.7
        )
    }
}
