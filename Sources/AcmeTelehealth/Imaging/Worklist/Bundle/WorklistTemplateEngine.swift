import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the worklist template calculation.
    protocol WorklistTemplateFactor {
        func describe() -> String
        func adjust(_ item: WorklistTemplate, value: Double) -> Double
    }

    final class MinimumWorklistTemplateAdjuster: WorklistTemplateFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WorklistTemplate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedWorklistTemplateAdjuster: WorklistTemplateFactor {
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

        func adjust(_ item: WorklistTemplate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentWorklistTemplateAdjuster: WorklistTemplateFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WorklistTemplate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredWorklistTemplateAdjuster: WorklistTemplateFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WorklistTemplate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class SourceWorklistTemplateAdjuster: WorklistTemplateFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: WorklistTemplate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingWorklistTemplateAdjuster: WorklistTemplateFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WorklistTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the worklist template steps in order and keeps a trace of each.
    final class WorklistTemplateEngine {
        var steps: [any WorklistTemplateFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WorklistTemplateFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: WorklistTemplate) -> Double {
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

        func evaluateAll(_ items: [WorklistTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultWorklistTemplateEngine(_ flags: Kit.Flags.Registry) -> WorklistTemplateEngine {
        return WorklistTemplateEngine(
            steps: [
                MinimumWorklistTemplateAdjuster(minimum: 6.1),
                FlaggedWorklistTemplateAdjuster(flags: flags, flag: "worklist-template-default", percent: 4.4),
                PercentWorklistTemplateAdjuster(percent: -22.1),
                TieredWorklistTemplateAdjuster(bounds: [423.0, 997.0, 4826.0], rates: [1.14, 1.01, 0.96]),
                SourceWorklistTemplateAdjuster(factors: ["north": 0.72, "east": 1.16]),
                RoundingWorklistTemplateAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 1009.6
        )
    }
}
