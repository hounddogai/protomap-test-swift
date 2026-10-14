import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the manual order set template calculation.
    protocol ManualOrderSetTemplateFactor {
        func describe() -> String
        func adjust(_ item: ManualOrderSetTemplate, value: Double) -> Double
    }

    final class FlaggedManualOrderSetTemplateAdjuster: ManualOrderSetTemplateFactor {
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

        func adjust(_ item: ManualOrderSetTemplate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ManualOrderSetTemplateCapacityOffsetAdjuster: ManualOrderSetTemplateFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: ManualOrderSetTemplate, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    final class UnitManualOrderSetTemplateAdjuster: ManualOrderSetTemplateFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: ManualOrderSetTemplate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingManualOrderSetTemplateAdjuster: ManualOrderSetTemplateFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualOrderSetTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredManualOrderSetTemplateAdjuster: ManualOrderSetTemplateFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualOrderSetTemplate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumManualOrderSetTemplateAdjuster: ManualOrderSetTemplateFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualOrderSetTemplate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the manual order set template steps in order and keeps a trace of each.
    final class ManualOrderSetTemplateEngine {
        var steps: [any ManualOrderSetTemplateFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualOrderSetTemplateFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ManualOrderSetTemplate) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualOrderSetTemplateFactor = steps[index]
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

        func evaluateAll(_ items: [ManualOrderSetTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultManualOrderSetTemplateEngine(_ flags: Kit.Flags.Registry) -> ManualOrderSetTemplateEngine {
        return ManualOrderSetTemplateEngine(
            steps: [
                FlaggedManualOrderSetTemplateAdjuster(
                    flags: flags,
                    flag: "manual-order-set-template-lenient",
                    percent: -3.4
                ),
                ManualOrderSetTemplateCapacityOffsetAdjuster(weight: 0.83),
                UnitManualOrderSetTemplateAdjuster(factors: ["central": 0.88, "west": 0.81]),
                RoundingManualOrderSetTemplateAdjuster(step: 5.0),
                TieredManualOrderSetTemplateAdjuster(bounds: [1173.0, 2689.0, 6098.0], rates: [1.12, 0.87, 1.17]),
                MinimumManualOrderSetTemplateAdjuster(minimum: 27.3),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 12514.5
        )
    }
}
