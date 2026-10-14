import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the float pool assignment calculation.
    protocol FloatPoolAssignmentAdjuster {
        func describe() -> String
        func adjust(_ item: FloatPoolAssignment, value: Double) -> Double
    }

    final class TitleFloatPoolAssignmentAdjuster: FloatPoolAssignmentAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: FloatPoolAssignment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapFloatPoolAssignmentAdjuster: FloatPoolAssignmentAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FloatPoolAssignment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingFloatPoolAssignmentAdjuster: FloatPoolAssignmentAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FloatPoolAssignment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the float pool assignment steps in order and keeps a trace of each.
    final class FloatPoolAssignmentEngine {
        var steps: [any FloatPoolAssignmentAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FloatPoolAssignmentAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FloatPoolAssignment) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any FloatPoolAssignmentAdjuster = steps[index]
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

        func evaluateAll(_ items: [FloatPoolAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFloatPoolAssignmentEngine() -> FloatPoolAssignmentEngine {
        return FloatPoolAssignmentEngine(
            steps: [
                TitleFloatPoolAssignmentAdjuster(factors: ["north": 0.91, "central": 0.84]),
                CapFloatPoolAssignmentAdjuster(cap: 1121.0),
                RoundingFloatPoolAssignmentAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 62745.2
        )
    }
}
