import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the default shift template calculation.
    protocol DefaultShiftTemplateAdjuster {
        func describe() -> String
        func adjust(_ item: DefaultShiftTemplate, value: Double) -> Double
    }

    final class LabelDefaultShiftTemplateAdjuster: DefaultShiftTemplateAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: DefaultShiftTemplate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapDefaultShiftTemplateAdjuster: DefaultShiftTemplateAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultShiftTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingDefaultShiftTemplateAdjuster: DefaultShiftTemplateAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultShiftTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the default shift template steps in order and keeps a trace of each.
    final class DefaultShiftTemplateEngine {
        var steps: [any DefaultShiftTemplateAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultShiftTemplateAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: DefaultShiftTemplate) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultShiftTemplateAdjuster = steps[index]
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

        func evaluateAll(_ items: [DefaultShiftTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultDefaultShiftTemplateEngine() -> DefaultShiftTemplateEngine {
        return DefaultShiftTemplateEngine(
            steps: [
                LabelDefaultShiftTemplateAdjuster(factors: ["west": 0.78, "north": 1.02]),
                CapDefaultShiftTemplateAdjuster(cap: 22853.0),
                RoundingDefaultShiftTemplateAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 87256.8
        )
    }
}
