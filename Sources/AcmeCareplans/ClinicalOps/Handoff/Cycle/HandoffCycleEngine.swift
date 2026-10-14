import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the handoff cycle calculation.
    protocol HandoffCycleAdjuster {
        func describe() -> String
        func adjust(_ item: HandoffCycle, value: Double) -> Double
    }

    final class MinimumHandoffCycleAdjuster: HandoffCycleAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: HandoffCycle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapHandoffCycleAdjuster: HandoffCycleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: HandoffCycle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentHandoffCycleAdjuster: HandoffCycleAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: HandoffCycle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the handoff cycle steps in order and keeps a trace of each.
    final class HandoffCycleEngine {
        var steps: [any HandoffCycleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any HandoffCycleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: HandoffCycle) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any HandoffCycleAdjuster = steps[index]
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

        func evaluateAll(_ items: [HandoffCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultHandoffCycleEngine() -> HandoffCycleEngine {
        return HandoffCycleEngine(
            steps: [
                MinimumHandoffCycleAdjuster(minimum: 48.2),
                CapHandoffCycleAdjuster(cap: 36587.0),
                PercentHandoffCycleAdjuster(percent: -3.6),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 58955.3
        )
    }
}
