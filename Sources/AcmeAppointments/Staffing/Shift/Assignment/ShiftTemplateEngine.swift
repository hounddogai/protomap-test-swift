import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the shift template calculation.
    protocol ShiftTemplateAdjuster {
        func describe() -> String
        func adjust(_ item: ShiftTemplate, value: Double) -> Double
    }

    final class WardShiftTemplateAdjuster: ShiftTemplateAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: ShiftTemplate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapShiftTemplateAdjuster: ShiftTemplateAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ShiftTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class ShiftTemplatePriorityOffsetAdjuster: ShiftTemplateAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus priority times \(weight)"
        }

        func adjust(_ item: ShiftTemplate, value: Double) -> Double {
            return value + Double(item.priority) * weight
        }
    }

    /// Runs the shift template steps in order and keeps a trace of each.
    final class ShiftTemplateEngine {
        var steps: [any ShiftTemplateAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ShiftTemplateAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ShiftTemplate) -> Double {
            var current = item.weightedValue()
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

        func evaluateAll(_ items: [ShiftTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultShiftTemplateEngine() -> ShiftTemplateEngine {
        return ShiftTemplateEngine(
            steps: [
                WardShiftTemplateAdjuster(factors: ["south": 1.21, "west": 1.39, "online": 0.91]),
                CapShiftTemplateAdjuster(cap: 43219.0),
                ShiftTemplatePriorityOffsetAdjuster(weight: 0.13),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 95054.3
        )
    }
}
