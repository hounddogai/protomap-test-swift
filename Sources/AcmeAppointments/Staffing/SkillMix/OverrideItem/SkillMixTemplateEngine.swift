import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the skill mix template calculation.
    protocol SkillMixTemplateFactor {
        func describe() -> String
        func adjust(_ item: SkillMixTemplate, value: Double) -> Double
    }

    final class TieredSkillMixTemplateAdjuster: SkillMixTemplateFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SkillMixTemplate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingSkillMixTemplateAdjuster: SkillMixTemplateFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SkillMixTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentSkillMixTemplateAdjuster: SkillMixTemplateFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SkillMixTemplate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapSkillMixTemplateAdjuster: SkillMixTemplateFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SkillMixTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumSkillMixTemplateAdjuster: SkillMixTemplateFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SkillMixTemplate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedSkillMixTemplateAdjuster: SkillMixTemplateFactor {
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

        func adjust(_ item: SkillMixTemplate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the skill mix template steps in order and keeps a trace of each.
    final class SkillMixTemplateEngine {
        var steps: [any SkillMixTemplateFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SkillMixTemplateFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: SkillMixTemplate) -> Double {
            var current = item.weightedTotal()
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

        func evaluateAll(_ items: [SkillMixTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultSkillMixTemplateEngine(_ flags: Kit.Flags.Registry) -> SkillMixTemplateEngine {
        return SkillMixTemplateEngine(
            steps: [
                TieredSkillMixTemplateAdjuster(
                    bounds: [4249.0, 4456.0, 6450.0, 9138.0],
                    rates: [0.91, 0.91, 1.14, 0.9]
                ),
                RoundingSkillMixTemplateAdjuster(step: 0.05),
                PercentSkillMixTemplateAdjuster(percent: -5.5),
                CapSkillMixTemplateAdjuster(cap: 33009.0),
                MinimumSkillMixTemplateAdjuster(minimum: 38.6),
                FlaggedSkillMixTemplateAdjuster(flags: flags, flag: "skill-mix-template-global", percent: 9.3),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 40215.6
        )
    }
}
