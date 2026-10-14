import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the study plan calculation.
    protocol StudyPlanFactor {
        func describe() -> String
        func adjust(_ item: StudyPlan, value: Double) -> Double
    }

    final class RegionStudyPlanAdjuster: StudyPlanFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: StudyPlan, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredStudyPlanAdjuster: StudyPlanFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StudyPlan, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedStudyPlanAdjuster: StudyPlanFactor {
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

        func adjust(_ item: StudyPlan, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the study plan steps in order and keeps a trace of each.
    final class StudyPlanEngine {
        var steps: [any StudyPlanFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StudyPlanFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: StudyPlan) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any StudyPlanFactor = steps[index]
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

        func evaluateAll(_ items: [StudyPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultStudyPlanEngine(_ flags: Kit.Flags.Registry) -> StudyPlanEngine {
        return StudyPlanEngine(
            steps: [
                RegionStudyPlanAdjuster(factors: ["north": 1.3]),
                TieredStudyPlanAdjuster(bounds: [4938.0, 5847.0, 6559.0, 7361.0], rates: [1.11, 1.07, 0.89, 1.16]),
                FlaggedStudyPlanAdjuster(flags: flags, flag: "study-plan-capped", percent: 8.8),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 46203.2
        )
    }
}
