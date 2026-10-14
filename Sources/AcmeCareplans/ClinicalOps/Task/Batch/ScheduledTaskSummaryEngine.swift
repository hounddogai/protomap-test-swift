import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the scheduled task summary calculation.
    protocol ScheduledTaskSummaryFactor {
        func describe() -> String
        func adjust(_ item: ScheduledTaskSummary, value: Double) -> Double
    }

    final class ScheduledTaskSummaryAmountOffsetAdjuster: ScheduledTaskSummaryFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: ScheduledTaskSummary, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class RoundingScheduledTaskSummaryAdjuster: ScheduledTaskSummaryFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledTaskSummary, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FacilityScheduledTaskSummaryAdjuster: ScheduledTaskSummaryFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: ScheduledTaskSummary, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the scheduled task summary steps in order and keeps a trace of each.
    final class ScheduledTaskSummaryEngine {
        var steps: [any ScheduledTaskSummaryFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledTaskSummaryFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ScheduledTaskSummary) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledTaskSummaryFactor = steps[index]
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

        func evaluateAll(_ items: [ScheduledTaskSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultScheduledTaskSummaryEngine() -> ScheduledTaskSummaryEngine {
        return ScheduledTaskSummaryEngine(
            steps: [
                ScheduledTaskSummaryAmountOffsetAdjuster(weight: 0.2),
                RoundingScheduledTaskSummaryAdjuster(step: 0.25),
                FacilityScheduledTaskSummaryAdjuster(factors: ["retail": 0.97]),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 37827.8
        )
    }
}
