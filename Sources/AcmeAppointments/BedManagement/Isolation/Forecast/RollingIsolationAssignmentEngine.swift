import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the rolling isolation assignment calculation.
    protocol RollingIsolationAssignmentStep {
        func describe() -> String
        func adjust(_ item: RollingIsolationAssignment, value: Double) -> Double
    }

    final class PercentRollingIsolationAssignmentAdjuster: RollingIsolationAssignmentStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingIsolationAssignment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumRollingIsolationAssignmentAdjuster: RollingIsolationAssignmentStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingIsolationAssignment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class NameRollingIsolationAssignmentAdjuster: RollingIsolationAssignmentStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: RollingIsolationAssignment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the rolling isolation assignment steps in order and keeps a trace of each.
    final class RollingIsolationAssignmentEngine {
        var steps: [any RollingIsolationAssignmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingIsolationAssignmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RollingIsolationAssignment) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingIsolationAssignmentStep = steps[index]
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

        func evaluateAll(_ items: [RollingIsolationAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRollingIsolationAssignmentEngine() -> RollingIsolationAssignmentEngine {
        return RollingIsolationAssignmentEngine(
            steps: [
                PercentRollingIsolationAssignmentAdjuster(percent: -10.0),
                MinimumRollingIsolationAssignmentAdjuster(minimum: 29.1),
                NameRollingIsolationAssignmentAdjuster(factors: ["east": 1.11]),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 29791.9
        )
    }
}
