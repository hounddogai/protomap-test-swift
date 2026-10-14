import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the scheduled shift template calculation.
    protocol ScheduledShiftTemplateFactor {
        func describe() -> String
        func adjust(_ item: ScheduledShiftTemplate, value: Double) -> Double
    }

    final class RoundingScheduledShiftTemplateAdjuster: ScheduledShiftTemplateFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledShiftTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumScheduledShiftTemplateAdjuster: ScheduledShiftTemplateFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledShiftTemplate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapScheduledShiftTemplateAdjuster: ScheduledShiftTemplateFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledShiftTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class ChannelScheduledShiftTemplateAdjuster: ScheduledShiftTemplateFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: ScheduledShiftTemplate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the scheduled shift template steps in order and keeps a trace of each.
    final class ScheduledShiftTemplateEngine {
        var steps: [any ScheduledShiftTemplateFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledShiftTemplateFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ScheduledShiftTemplate) -> Double {
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

        func evaluateAll(_ items: [ScheduledShiftTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultScheduledShiftTemplateEngine() -> ScheduledShiftTemplateEngine {
        return ScheduledShiftTemplateEngine(
            steps: [
                RoundingScheduledShiftTemplateAdjuster(step: 0.05),
                MinimumScheduledShiftTemplateAdjuster(minimum: 23.6),
                CapScheduledShiftTemplateAdjuster(cap: 21792.0),
                ChannelScheduledShiftTemplateAdjuster(factors: ["retail": 1.19, "central": 1.12]),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 81480.9
        )
    }
}
