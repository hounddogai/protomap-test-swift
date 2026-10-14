import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the strict skill mix template calculation.
    protocol StrictSkillMixTemplateFactor {
        func describe() -> String
        func adjust(_ item: StrictSkillMixTemplate, value: Double) -> Double
    }

    final class RoundingStrictSkillMixTemplateAdjuster: StrictSkillMixTemplateFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictSkillMixTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TitleStrictSkillMixTemplateAdjuster: StrictSkillMixTemplateFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: StrictSkillMixTemplate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentStrictSkillMixTemplateAdjuster: StrictSkillMixTemplateFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictSkillMixTemplate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the strict skill mix template steps in order and keeps a trace of each.
    final class StrictSkillMixTemplateEngine {
        var steps: [any StrictSkillMixTemplateFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictSkillMixTemplateFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: StrictSkillMixTemplate) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any StrictSkillMixTemplateFactor = steps[index]
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

        func evaluateAll(_ items: [StrictSkillMixTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultStrictSkillMixTemplateEngine() -> StrictSkillMixTemplateEngine {
        return StrictSkillMixTemplateEngine(
            steps: [
                RoundingStrictSkillMixTemplateAdjuster(step: 0.5),
                TitleStrictSkillMixTemplateAdjuster(factors: ["west": 1.32, "east": 1.0]),
                PercentStrictSkillMixTemplateAdjuster(percent: 23.6),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 99435.6
        )
    }
}
