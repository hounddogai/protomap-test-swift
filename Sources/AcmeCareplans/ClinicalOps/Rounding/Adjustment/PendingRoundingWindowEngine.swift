import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the pending rounding window calculation.
    protocol PendingRoundingWindowStep {
        func describe() -> String
        func adjust(_ item: PendingRoundingWindow, value: Double) -> Double
    }

    final class MinimumPendingRoundingWindowAdjuster: PendingRoundingWindowStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingRoundingWindow, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapPendingRoundingWindowAdjuster: PendingRoundingWindowStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingRoundingWindow, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentPendingRoundingWindowAdjuster: PendingRoundingWindowStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingRoundingWindow, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the pending rounding window steps in order and keeps a trace of each.
    final class PendingRoundingWindowEngine {
        var steps: [any PendingRoundingWindowStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingRoundingWindowStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PendingRoundingWindow) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingRoundingWindowStep = steps[index]
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

        func evaluateAll(_ items: [PendingRoundingWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPendingRoundingWindowEngine() -> PendingRoundingWindowEngine {
        return PendingRoundingWindowEngine(
            steps: [
                MinimumPendingRoundingWindowAdjuster(minimum: 45.3),
                CapPendingRoundingWindowAdjuster(cap: 33974.0),
                PercentPendingRoundingWindowAdjuster(percent: 7.1),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 39852.8
        )
    }
}
