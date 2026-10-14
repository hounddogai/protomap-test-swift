import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the pending handoff target calculation.
    protocol PendingHandoffTargetAdjuster {
        func describe() -> String
        func adjust(_ item: PendingHandoffTarget, value: Double) -> Double
    }

    final class MinimumPendingHandoffTargetAdjuster: PendingHandoffTargetAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingHandoffTarget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapPendingHandoffTargetAdjuster: PendingHandoffTargetAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingHandoffTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingPendingHandoffTargetAdjuster: PendingHandoffTargetAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingHandoffTarget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the pending handoff target steps in order and keeps a trace of each.
    final class PendingHandoffTargetEngine {
        var steps: [any PendingHandoffTargetAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingHandoffTargetAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PendingHandoffTarget) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingHandoffTargetAdjuster = steps[index]
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

        func evaluateAll(_ items: [PendingHandoffTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPendingHandoffTargetEngine() -> PendingHandoffTargetEngine {
        return PendingHandoffTargetEngine(
            steps: [
                MinimumPendingHandoffTargetAdjuster(minimum: 2.8),
                CapPendingHandoffTargetAdjuster(cap: 27216.0),
                RoundingPendingHandoffTargetAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 88097.7
        )
    }
}
