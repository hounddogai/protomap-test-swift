import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the handoff template calculation.
    protocol HandoffTemplateModifier {
        func describe() -> String
        func adjust(_ item: HandoffTemplate, value: Double) -> Double
    }

    final class CapHandoffTemplateAdjuster: HandoffTemplateModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: HandoffTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedHandoffTemplateAdjuster: HandoffTemplateModifier {
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

        func adjust(_ item: HandoffTemplate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentHandoffTemplateAdjuster: HandoffTemplateModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: HandoffTemplate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingHandoffTemplateAdjuster: HandoffTemplateModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: HandoffTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the handoff template steps in order and keeps a trace of each.
    final class HandoffTemplateEngine {
        var steps: [any HandoffTemplateModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any HandoffTemplateModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: HandoffTemplate) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [HandoffTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultHandoffTemplateEngine(_ flags: Kit.Flags.Registry) -> HandoffTemplateEngine {
        return HandoffTemplateEngine(
            steps: [
                CapHandoffTemplateAdjuster(cap: 22496.0),
                FlaggedHandoffTemplateAdjuster(flags: flags, flag: "handoff-template-strict", percent: 8.7),
                PercentHandoffTemplateAdjuster(percent: -1.0),
                RoundingHandoffTemplateAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 27380.2
        )
    }
}
