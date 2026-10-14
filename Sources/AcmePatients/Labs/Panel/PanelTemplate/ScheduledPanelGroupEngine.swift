import AcmePlatform
import Foundation

extension Labs {
    /// One step of the scheduled panel group calculation.
    protocol ScheduledPanelGroupAdjuster {
        func describe() -> String
        func adjust(_ item: ScheduledPanelGroup, value: Double) -> Double
    }

    final class RoundingScheduledPanelGroupAdjuster: ScheduledPanelGroupAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledPanelGroup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class ScheduledPanelGroupCostOffsetAdjuster: ScheduledPanelGroupAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: ScheduledPanelGroup, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    final class PercentScheduledPanelGroupAdjuster: ScheduledPanelGroupAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledPanelGroup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the scheduled panel group steps in order and keeps a trace of each.
    final class ScheduledPanelGroupEngine {
        var steps: [any ScheduledPanelGroupAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledPanelGroupAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ScheduledPanelGroup) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledPanelGroupAdjuster = steps[index]
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

        func evaluateAll(_ items: [ScheduledPanelGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultScheduledPanelGroupEngine() -> ScheduledPanelGroupEngine {
        return ScheduledPanelGroupEngine(
            steps: [
                RoundingScheduledPanelGroupAdjuster(step: 0.25),
                ScheduledPanelGroupCostOffsetAdjuster(weight: 1.58),
                PercentScheduledPanelGroupAdjuster(percent: -10.7),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 80735.0
        )
    }
}
