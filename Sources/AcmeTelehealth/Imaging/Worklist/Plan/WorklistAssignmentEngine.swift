import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the worklist assignment calculation.
    protocol WorklistAssignmentAdjuster {
        func describe() -> String
        func adjust(_ item: WorklistAssignment, value: Double) -> Double
    }

    final class TieredWorklistAssignmentAdjuster: WorklistAssignmentAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WorklistAssignment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumWorklistAssignmentAdjuster: WorklistAssignmentAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WorklistAssignment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedWorklistAssignmentAdjuster: WorklistAssignmentAdjuster {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: WorklistAssignment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class WorklistAssignmentQuantityOffsetAdjuster: WorklistAssignmentAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: WorklistAssignment, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class CapWorklistAssignmentAdjuster: WorklistAssignmentAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WorklistAssignment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the worklist assignment steps in order and keeps a trace of each.
    final class WorklistAssignmentEngine {
        var steps: [any WorklistAssignmentAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WorklistAssignmentAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: WorklistAssignment) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any WorklistAssignmentAdjuster = steps[index]
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

        func evaluateAll(_ items: [WorklistAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultWorklistAssignmentEngine(_ flags: Kit.Flags.Registry) -> WorklistAssignmentEngine {
        return WorklistAssignmentEngine(
            steps: [
                TieredWorklistAssignmentAdjuster(bounds: [3402.0, 4177.0, 7715.0], rates: [1.03, 1.16, 1.19]),
                MinimumWorklistAssignmentAdjuster(minimum: 10.2),
                FlaggedWorklistAssignmentAdjuster(flags: flags, flag: "worklist-assignment-capped", percent: -2.4),
                WorklistAssignmentQuantityOffsetAdjuster(weight: 0.56),
                CapWorklistAssignmentAdjuster(cap: 13786.0),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 55699.7
        )
    }
}
