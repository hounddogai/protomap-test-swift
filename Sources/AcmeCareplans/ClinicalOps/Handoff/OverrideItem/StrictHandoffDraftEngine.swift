import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the strict handoff draft calculation.
    protocol StrictHandoffDraftAdjuster {
        func describe() -> String
        func adjust(_ item: StrictHandoffDraft, value: Double) -> Double
    }

    final class PercentStrictHandoffDraftAdjuster: StrictHandoffDraftAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictHandoffDraft, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumStrictHandoffDraftAdjuster: StrictHandoffDraftAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictHandoffDraft, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingStrictHandoffDraftAdjuster: StrictHandoffDraftAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictHandoffDraft, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the strict handoff draft steps in order and keeps a trace of each.
    final class StrictHandoffDraftEngine {
        var steps: [any StrictHandoffDraftAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictHandoffDraftAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: StrictHandoffDraft) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any StrictHandoffDraftAdjuster = steps[index]
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

        func evaluateAll(_ items: [StrictHandoffDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultStrictHandoffDraftEngine() -> StrictHandoffDraftEngine {
        return StrictHandoffDraftEngine(
            steps: [
                PercentStrictHandoffDraftAdjuster(percent: 8.2),
                MinimumStrictHandoffDraftAdjuster(minimum: 40.8),
                RoundingStrictHandoffDraftAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 25132.6
        )
    }
}
