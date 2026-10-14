import AcmePlatform
import Foundation

extension Consent {
    /// One step of the witness assignment calculation.
    protocol WitnessAssignmentStep {
        func describe() -> String
        func adjust(_ item: WitnessAssignment, value: Double) -> Double
    }

    final class MinimumWitnessAssignmentAdjuster: WitnessAssignmentStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WitnessAssignment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentWitnessAssignmentAdjuster: WitnessAssignmentStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WitnessAssignment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapWitnessAssignmentAdjuster: WitnessAssignmentStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WitnessAssignment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class CategoryWitnessAssignmentAdjuster: WitnessAssignmentStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: WitnessAssignment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the witness assignment steps in order and keeps a trace of each.
    final class WitnessAssignmentEngine {
        var steps: [any WitnessAssignmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WitnessAssignmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: WitnessAssignment) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any WitnessAssignmentStep = steps[index]
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

        func evaluateAll(_ items: [WitnessAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultWitnessAssignmentEngine() -> WitnessAssignmentEngine {
        return WitnessAssignmentEngine(
            steps: [
                MinimumWitnessAssignmentAdjuster(minimum: 37.6),
                PercentWitnessAssignmentAdjuster(percent: 21.5),
                CapWitnessAssignmentAdjuster(cap: 37556.0),
                CategoryWitnessAssignmentAdjuster(factors: ["retail": 1.36]),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 63992.2
        )
    }
}
