import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the shift audit calculation.
    protocol ShiftAuditModifier {
        func describe() -> String
        func adjust(_ item: ShiftAudit, value: Double) -> Double
    }

    final class TieredShiftAuditAdjuster: ShiftAuditModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ShiftAudit, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class TitleShiftAuditAdjuster: ShiftAuditModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: ShiftAudit, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingShiftAuditAdjuster: ShiftAuditModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ShiftAudit, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the shift audit steps in order and keeps a trace of each.
    final class ShiftAuditEngine {
        var steps: [any ShiftAuditModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ShiftAuditModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ShiftAudit) -> Double {
            var current = item.adjustedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any ShiftAuditModifier = steps[index]
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

        func evaluateAll(_ items: [ShiftAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultShiftAuditEngine() -> ShiftAuditEngine {
        return ShiftAuditEngine(
            steps: [
                TieredShiftAuditAdjuster(bounds: [409.0, 4933.0], rates: [1.16, 0.82]),
                TitleShiftAuditAdjuster(factors: ["east": 0.77, "north": 1.17]),
                RoundingShiftAuditAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 43129.9
        )
    }
}
