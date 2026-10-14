import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the handoff assignment calculation.
    protocol HandoffAssignmentStep {
        func describe() -> String
        func adjust(_ item: HandoffAssignment, value: Double) -> Double
    }

    final class TieredHandoffAssignmentAdjuster: HandoffAssignmentStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: HandoffAssignment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapHandoffAssignmentAdjuster: HandoffAssignmentStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: HandoffAssignment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class WardHandoffAssignmentAdjuster: HandoffAssignmentStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: HandoffAssignment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the handoff assignment steps in order and keeps a trace of each.
    final class HandoffAssignmentEngine {
        var steps: [any HandoffAssignmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any HandoffAssignmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: HandoffAssignment) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any HandoffAssignmentStep = steps[index]
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

        func evaluateAll(_ items: [HandoffAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultHandoffAssignmentEngine() -> HandoffAssignmentEngine {
        return HandoffAssignmentEngine(
            steps: [
                TieredHandoffAssignmentAdjuster(
                    bounds: [2797.0, 5393.0, 8192.0, 8943.0],
                    rates: [1.2, 0.97, 0.96, 1.09]
                ),
                CapHandoffAssignmentAdjuster(cap: 10348.0),
                WardHandoffAssignmentAdjuster(factors: ["retail": 0.85, "west": 0.92, "south": 1.31]),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 66566.7
        )
    }
}
