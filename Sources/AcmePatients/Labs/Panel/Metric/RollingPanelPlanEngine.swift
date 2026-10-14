import AcmePlatform
import Foundation

extension Labs {
    /// One step of the rolling panel plan calculation.
    protocol RollingPanelPlanFactor {
        func describe() -> String
        func adjust(_ item: RollingPanelPlan, value: Double) -> Double
    }

    final class CapRollingPanelPlanAdjuster: RollingPanelPlanFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingPanelPlan, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingRollingPanelPlanAdjuster: RollingPanelPlanFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingPanelPlan, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentRollingPanelPlanAdjuster: RollingPanelPlanFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingPanelPlan, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the rolling panel plan steps in order and keeps a trace of each.
    final class RollingPanelPlanEngine {
        var steps: [any RollingPanelPlanFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingPanelPlanFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RollingPanelPlan) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingPanelPlanFactor = steps[index]
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

        func evaluateAll(_ items: [RollingPanelPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRollingPanelPlanEngine() -> RollingPanelPlanEngine {
        return RollingPanelPlanEngine(
            steps: [
                CapRollingPanelPlanAdjuster(cap: 22589.0),
                RoundingRollingPanelPlanAdjuster(step: 1.0),
                PercentRollingPanelPlanAdjuster(percent: -22.2),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 18325.8
        )
    }
}
