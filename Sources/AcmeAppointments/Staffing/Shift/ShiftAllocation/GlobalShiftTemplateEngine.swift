import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the global shift template calculation.
    protocol GlobalShiftTemplateFactor {
        func describe() -> String
        func adjust(_ item: GlobalShiftTemplate, value: Double) -> Double
    }

    final class GlobalShiftTemplateMinimumOffsetAdjuster: GlobalShiftTemplateFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: GlobalShiftTemplate, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    final class FlaggedGlobalShiftTemplateAdjuster: GlobalShiftTemplateFactor {
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

        func adjust(_ item: GlobalShiftTemplate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelGlobalShiftTemplateAdjuster: GlobalShiftTemplateFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: GlobalShiftTemplate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumGlobalShiftTemplateAdjuster: GlobalShiftTemplateFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalShiftTemplate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingGlobalShiftTemplateAdjuster: GlobalShiftTemplateFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalShiftTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapGlobalShiftTemplateAdjuster: GlobalShiftTemplateFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalShiftTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the global shift template steps in order and keeps a trace of each.
    final class GlobalShiftTemplateEngine {
        var steps: [any GlobalShiftTemplateFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalShiftTemplateFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: GlobalShiftTemplate) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalShiftTemplateFactor = steps[index]
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

        func evaluateAll(_ items: [GlobalShiftTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultGlobalShiftTemplateEngine(_ flags: Kit.Flags.Registry) -> GlobalShiftTemplateEngine {
        return GlobalShiftTemplateEngine(
            steps: [
                GlobalShiftTemplateMinimumOffsetAdjuster(weight: 1.1),
                FlaggedGlobalShiftTemplateAdjuster(flags: flags, flag: "global-shift-template-capped", percent: 2.4),
                LabelGlobalShiftTemplateAdjuster(factors: ["west": 1.35, "central": 0.78, "north": 1.0]),
                MinimumGlobalShiftTemplateAdjuster(minimum: 33.0),
                RoundingGlobalShiftTemplateAdjuster(step: 1.0),
                CapGlobalShiftTemplateAdjuster(cap: 19135.0),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 81293.7
        )
    }
}
