import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the default program assignment calculation.
    protocol DefaultProgramAssignmentStep {
        func describe() -> String
        func adjust(_ item: DefaultProgramAssignment, value: Double) -> Double
    }

    final class RoundingDefaultProgramAssignmentAdjuster: DefaultProgramAssignmentStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultProgramAssignment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TitleDefaultProgramAssignmentAdjuster: DefaultProgramAssignmentStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: DefaultProgramAssignment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentDefaultProgramAssignmentAdjuster: DefaultProgramAssignmentStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultProgramAssignment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the default program assignment steps in order and keeps a trace of each.
    final class DefaultProgramAssignmentEngine {
        var steps: [any DefaultProgramAssignmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultProgramAssignmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: DefaultProgramAssignment) -> Double {
            var current = item.netValue()
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

        func evaluateAll(_ items: [DefaultProgramAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultDefaultProgramAssignmentEngine() -> DefaultProgramAssignmentEngine {
        return DefaultProgramAssignmentEngine(
            steps: [
                RoundingDefaultProgramAssignmentAdjuster(step: 5.0),
                TitleDefaultProgramAssignmentAdjuster(factors: ["east": 0.72]),
                PercentDefaultProgramAssignmentAdjuster(percent: 5.1),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 26819.5
        )
    }
}
