import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the primary task template calculation.
    protocol PrimaryTaskTemplateStep {
        func describe() -> String
        func adjust(_ item: PrimaryTaskTemplate, value: Double) -> Double
    }

    final class FlaggedPrimaryTaskTemplateAdjuster: PrimaryTaskTemplateStep {
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

        func adjust(_ item: PrimaryTaskTemplate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapPrimaryTaskTemplateAdjuster: PrimaryTaskTemplateStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryTaskTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentPrimaryTaskTemplateAdjuster: PrimaryTaskTemplateStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryTaskTemplate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumPrimaryTaskTemplateAdjuster: PrimaryTaskTemplateStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryTaskTemplate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingPrimaryTaskTemplateAdjuster: PrimaryTaskTemplateStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryTaskTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the primary task template steps in order and keeps a trace of each.
    final class PrimaryTaskTemplateEngine {
        var steps: [any PrimaryTaskTemplateStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryTaskTemplateStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PrimaryTaskTemplate) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimaryTaskTemplateStep = steps[index]
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

        func evaluateAll(_ items: [PrimaryTaskTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPrimaryTaskTemplateEngine(_ flags: Kit.Flags.Registry) -> PrimaryTaskTemplateEngine {
        return PrimaryTaskTemplateEngine(
            steps: [
                FlaggedPrimaryTaskTemplateAdjuster(flags: flags, flag: "primary-task-template-batched", percent: 8.9),
                CapPrimaryTaskTemplateAdjuster(cap: 20097.0),
                PercentPrimaryTaskTemplateAdjuster(percent: -2.7),
                MinimumPrimaryTaskTemplateAdjuster(minimum: 48.4),
                RoundingPrimaryTaskTemplateAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 87662.8
        )
    }
}
