import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the handoff milestone calculation.
    protocol HandoffMilestoneAdjuster {
        func describe() -> String
        func adjust(_ item: HandoffMilestone, value: Double) -> Double
    }

    final class HandoffMilestoneRateOffsetAdjuster: HandoffMilestoneAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: HandoffMilestone, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    final class CapHandoffMilestoneAdjuster: HandoffMilestoneAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: HandoffMilestone, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumHandoffMilestoneAdjuster: HandoffMilestoneAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: HandoffMilestone, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the handoff milestone steps in order and keeps a trace of each.
    final class HandoffMilestoneEngine {
        var steps: [any HandoffMilestoneAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any HandoffMilestoneAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: HandoffMilestone) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any HandoffMilestoneAdjuster = steps[index]
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

        func evaluateAll(_ items: [HandoffMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultHandoffMilestoneEngine() -> HandoffMilestoneEngine {
        return HandoffMilestoneEngine(
            steps: [
                HandoffMilestoneRateOffsetAdjuster(weight: 0.57),
                CapHandoffMilestoneAdjuster(cap: 37397.0),
                MinimumHandoffMilestoneAdjuster(minimum: 26.7),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 63171.0
        )
    }
}
