import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the adaptive rounding template calculation.
    protocol AdaptiveRoundingTemplateModifier {
        func describe() -> String
        func adjust(_ item: AdaptiveRoundingTemplate, value: Double) -> Double
    }

    final class FlaggedAdaptiveRoundingTemplateAdjuster: AdaptiveRoundingTemplateModifier {
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

        func adjust(_ item: AdaptiveRoundingTemplate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapAdaptiveRoundingTemplateAdjuster: AdaptiveRoundingTemplateModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveRoundingTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingAdaptiveRoundingTemplateAdjuster: AdaptiveRoundingTemplateModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveRoundingTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the adaptive rounding template steps in order and keeps a trace of each.
    final class AdaptiveRoundingTemplateEngine {
        var steps: [any AdaptiveRoundingTemplateModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveRoundingTemplateModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AdaptiveRoundingTemplate) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveRoundingTemplateModifier = steps[index]
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

        func evaluateAll(_ items: [AdaptiveRoundingTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAdaptiveRoundingTemplateEngine(_ flags: Kit.Flags.Registry) -> AdaptiveRoundingTemplateEngine {
        return AdaptiveRoundingTemplateEngine(
            steps: [
                FlaggedAdaptiveRoundingTemplateAdjuster(
                    flags: flags,
                    flag: "adaptive-rounding-template-seasonal",
                    percent: 7.4
                ),
                CapAdaptiveRoundingTemplateAdjuster(cap: 29239.0),
                RoundingAdaptiveRoundingTemplateAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 99238.7
        )
    }
}
