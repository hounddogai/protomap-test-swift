import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the care gap template calculation.
    protocol CareGapTemplateModifier {
        func describe() -> String
        func adjust(_ item: CareGapTemplate, value: Double) -> Double
    }

    final class FlaggedCareGapTemplateAdjuster: CareGapTemplateModifier {
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

        func adjust(_ item: CareGapTemplate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingCareGapTemplateAdjuster: CareGapTemplateModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CareGapTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CareGapTemplatePriorityOffsetAdjuster: CareGapTemplateModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus priority times \(weight)"
        }

        func adjust(_ item: CareGapTemplate, value: Double) -> Double {
            return value + Double(item.priority) * weight
        }
    }

    final class TieredCareGapTemplateAdjuster: CareGapTemplateModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CareGapTemplate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentCareGapTemplateAdjuster: CareGapTemplateModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CareGapTemplate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the care gap template steps in order and keeps a trace of each.
    final class CareGapTemplateEngine {
        var steps: [any CareGapTemplateModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareGapTemplateModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CareGapTemplate) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any CareGapTemplateModifier = steps[index]
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

        func evaluateAll(_ items: [CareGapTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCareGapTemplateEngine(_ flags: Kit.Flags.Registry) -> CareGapTemplateEngine {
        return CareGapTemplateEngine(
            steps: [
                FlaggedCareGapTemplateAdjuster(flags: flags, flag: "care-gap-template-weighted", percent: 9.8),
                RoundingCareGapTemplateAdjuster(step: 0.1),
                CareGapTemplatePriorityOffsetAdjuster(weight: 0.28),
                TieredCareGapTemplateAdjuster(bounds: [4418.0, 6877.0], rates: [1.12, 1.09]),
                PercentCareGapTemplateAdjuster(percent: 13.2),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 47584.7
        )
    }
}
