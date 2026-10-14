import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the pending modality notice calculation.
    protocol PendingModalityNoticeStep {
        func describe() -> String
        func adjust(_ item: PendingModalityNotice, value: Double) -> Double
    }

    final class CapPendingModalityNoticeAdjuster: PendingModalityNoticeStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingModalityNotice, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumPendingModalityNoticeAdjuster: PendingModalityNoticeStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingModalityNotice, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingPendingModalityNoticeAdjuster: PendingModalityNoticeStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingModalityNotice, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the pending modality notice steps in order and keeps a trace of each.
    final class PendingModalityNoticeEngine {
        var steps: [any PendingModalityNoticeStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingModalityNoticeStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PendingModalityNotice) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingModalityNoticeStep = steps[index]
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

        func evaluateAll(_ items: [PendingModalityNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPendingModalityNoticeEngine() -> PendingModalityNoticeEngine {
        return PendingModalityNoticeEngine(
            steps: [
                CapPendingModalityNoticeAdjuster(cap: 5797.0),
                MinimumPendingModalityNoticeAdjuster(minimum: 1.0),
                RoundingPendingModalityNoticeAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 70168.7
        )
    }
}
