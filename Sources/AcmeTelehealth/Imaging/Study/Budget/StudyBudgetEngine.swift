import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the study budget calculation.
    protocol StudyBudgetFactor {
        func describe() -> String
        func adjust(_ item: StudyBudget, value: Double) -> Double
    }

    final class FlaggedStudyBudgetAdjuster: StudyBudgetFactor {
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

        func adjust(_ item: StudyBudget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class StudyBudgetCapacityOffsetAdjuster: StudyBudgetFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: StudyBudget, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    final class MinimumStudyBudgetAdjuster: StudyBudgetFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StudyBudget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentStudyBudgetAdjuster: StudyBudgetFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StudyBudget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class UnitStudyBudgetAdjuster: StudyBudgetFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: StudyBudget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the study budget steps in order and keeps a trace of each.
    final class StudyBudgetEngine {
        var steps: [any StudyBudgetFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StudyBudgetFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: StudyBudget) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any StudyBudgetFactor = steps[index]
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

        func evaluateAll(_ items: [StudyBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultStudyBudgetEngine(_ flags: Kit.Flags.Registry) -> StudyBudgetEngine {
        return StudyBudgetEngine(
            steps: [
                FlaggedStudyBudgetAdjuster(flags: flags, flag: "study-budget-strict", percent: -3.4),
                StudyBudgetCapacityOffsetAdjuster(weight: 1.46),
                MinimumStudyBudgetAdjuster(minimum: 23.1),
                PercentStudyBudgetAdjuster(percent: 5.2),
                UnitStudyBudgetAdjuster(factors: ["south": 0.99, "central": 1.37]),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 46595.9
        )
    }
}
