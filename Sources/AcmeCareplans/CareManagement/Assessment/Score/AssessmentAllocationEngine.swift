import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the assessment allocation calculation.
    protocol AssessmentAllocationAdjuster {
        func describe() -> String
        func adjust(_ item: AssessmentAllocation, value: Double) -> Double
    }

    final class FlaggedAssessmentAllocationAdjuster: AssessmentAllocationAdjuster {
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

        func adjust(_ item: AssessmentAllocation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapAssessmentAllocationAdjuster: AssessmentAllocationAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AssessmentAllocation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumAssessmentAllocationAdjuster: AssessmentAllocationAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AssessmentAllocation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class NameAssessmentAllocationAdjuster: AssessmentAllocationAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: AssessmentAllocation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the assessment allocation steps in order and keeps a trace of each.
    final class AssessmentAllocationEngine {
        var steps: [any AssessmentAllocationAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AssessmentAllocationAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AssessmentAllocation) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any AssessmentAllocationAdjuster = steps[index]
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

        func evaluateAll(_ items: [AssessmentAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAssessmentAllocationEngine(_ flags: Kit.Flags.Registry) -> AssessmentAllocationEngine {
        return AssessmentAllocationEngine(
            steps: [
                FlaggedAssessmentAllocationAdjuster(flags: flags, flag: "assessment-allocation-manual", percent: 7.8),
                CapAssessmentAllocationAdjuster(cap: 36316.0),
                MinimumAssessmentAllocationAdjuster(minimum: 21.3),
                NameAssessmentAllocationAdjuster(factors: ["central": 1.33, "north": 0.75]),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 10764.2
        )
    }
}
