import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the overtime template calculation.
    protocol OvertimeTemplateModifier {
        func describe() -> String
        func adjust(_ item: OvertimeTemplate, value: Double) -> Double
    }

    final class MinimumOvertimeTemplateAdjuster: OvertimeTemplateModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: OvertimeTemplate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class OvertimeTemplateDosageMgOffsetAdjuster: OvertimeTemplateModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: OvertimeTemplate, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    final class TieredOvertimeTemplateAdjuster: OvertimeTemplateModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: OvertimeTemplate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the overtime template steps in order and keeps a trace of each.
    final class OvertimeTemplateEngine {
        var steps: [any OvertimeTemplateModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OvertimeTemplateModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: OvertimeTemplate) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any OvertimeTemplateModifier = steps[index]
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

        func evaluateAll(_ items: [OvertimeTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultOvertimeTemplateEngine() -> OvertimeTemplateEngine {
        return OvertimeTemplateEngine(
            steps: [
                MinimumOvertimeTemplateAdjuster(minimum: 4.0),
                OvertimeTemplateDosageMgOffsetAdjuster(weight: 1.92),
                TieredOvertimeTemplateAdjuster(bounds: [3364.0, 8815.0, 9419.0], rates: [1.2, 1.05, 0.92]),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 26452.6
        )
    }
}
