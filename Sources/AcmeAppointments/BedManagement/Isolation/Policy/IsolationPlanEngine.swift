import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the isolation plan calculation.
    protocol IsolationPlanStep {
        func describe() -> String
        func adjust(_ item: IsolationPlan, value: Double) -> Double
    }

    final class CapIsolationPlanAdjuster: IsolationPlanStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: IsolationPlan, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class IsolationPlanStartsAtOffsetAdjuster: IsolationPlanStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: IsolationPlan, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    final class MinimumIsolationPlanAdjuster: IsolationPlanStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: IsolationPlan, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentIsolationPlanAdjuster: IsolationPlanStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: IsolationPlan, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingIsolationPlanAdjuster: IsolationPlanStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: IsolationPlan, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the isolation plan steps in order and keeps a trace of each.
    final class IsolationPlanEngine {
        var steps: [any IsolationPlanStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any IsolationPlanStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: IsolationPlan) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any IsolationPlanStep = steps[index]
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

        func evaluateAll(_ items: [IsolationPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultIsolationPlanEngine() -> IsolationPlanEngine {
        return IsolationPlanEngine(
            steps: [
                CapIsolationPlanAdjuster(cap: 49531.0),
                IsolationPlanStartsAtOffsetAdjuster(weight: 0.09),
                MinimumIsolationPlanAdjuster(minimum: 48.4),
                PercentIsolationPlanAdjuster(percent: 3.1),
                RoundingIsolationPlanAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 5014.5
        )
    }
}
