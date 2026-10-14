import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the regional task assignment calculation.
    protocol RegionalTaskAssignmentStep {
        func describe() -> String
        func adjust(_ item: RegionalTaskAssignment, value: Double) -> Double
    }

    final class FlaggedRegionalTaskAssignmentAdjuster: RegionalTaskAssignmentStep {
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

        func adjust(_ item: RegionalTaskAssignment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingRegionalTaskAssignmentAdjuster: RegionalTaskAssignmentStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalTaskAssignment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumRegionalTaskAssignmentAdjuster: RegionalTaskAssignmentStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalTaskAssignment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the regional task assignment steps in order and keeps a trace of each.
    final class RegionalTaskAssignmentEngine {
        var steps: [any RegionalTaskAssignmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalTaskAssignmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RegionalTaskAssignment) -> Double {
            var current = item.effectiveValue()
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

        func evaluateAll(_ items: [RegionalTaskAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRegionalTaskAssignmentEngine(_ flags: Kit.Flags.Registry) -> RegionalTaskAssignmentEngine {
        return RegionalTaskAssignmentEngine(
            steps: [
                FlaggedRegionalTaskAssignmentAdjuster(
                    flags: flags,
                    flag: "regional-task-assignment-pending",
                    percent: 8.1
                ),
                RoundingRegionalTaskAssignmentAdjuster(step: 0.5),
                MinimumRegionalTaskAssignmentAdjuster(minimum: 39.8),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 67293.0
        )
    }
}
