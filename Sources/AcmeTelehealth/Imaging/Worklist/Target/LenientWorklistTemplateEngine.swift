import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the lenient worklist template calculation.
    protocol LenientWorklistTemplateFactor {
        func describe() -> String
        func adjust(_ item: LenientWorklistTemplate, value: Double) -> Double
    }

    final class MinimumLenientWorklistTemplateAdjuster: LenientWorklistTemplateFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientWorklistTemplate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapLenientWorklistTemplateAdjuster: LenientWorklistTemplateFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientWorklistTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingLenientWorklistTemplateAdjuster: LenientWorklistTemplateFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientWorklistTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedLenientWorklistTemplateAdjuster: LenientWorklistTemplateFactor {
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

        func adjust(_ item: LenientWorklistTemplate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LenientWorklistTemplateVersionOffsetAdjuster: LenientWorklistTemplateFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus version times \(weight)"
        }

        func adjust(_ item: LenientWorklistTemplate, value: Double) -> Double {
            return value + Double(item.version) * weight
        }
    }

    final class LabelLenientWorklistTemplateAdjuster: LenientWorklistTemplateFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: LenientWorklistTemplate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the lenient worklist template steps in order and keeps a trace of each.
    final class LenientWorklistTemplateEngine {
        var steps: [any LenientWorklistTemplateFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientWorklistTemplateFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LenientWorklistTemplate) -> Double {
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

        func evaluateAll(_ items: [LenientWorklistTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLenientWorklistTemplateEngine(_ flags: Kit.Flags.Registry) -> LenientWorklistTemplateEngine {
        return LenientWorklistTemplateEngine(
            steps: [
                MinimumLenientWorklistTemplateAdjuster(minimum: 46.8),
                CapLenientWorklistTemplateAdjuster(cap: 39182.0),
                RoundingLenientWorklistTemplateAdjuster(step: 1.0),
                FlaggedLenientWorklistTemplateAdjuster(
                    flags: flags,
                    flag: "lenient-worklist-template-strict",
                    percent: 1.9
                ),
                LenientWorklistTemplateVersionOffsetAdjuster(weight: 0.06),
                LabelLenientWorklistTemplateAdjuster(factors: ["retail": 1.21, "central": 0.7, "online": 0.96]),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 93560.6
        )
    }
}
