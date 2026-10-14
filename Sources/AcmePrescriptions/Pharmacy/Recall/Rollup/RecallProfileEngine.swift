import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the recall profile calculation.
    protocol RecallProfileStep {
        func describe() -> String
        func adjust(_ item: RecallProfile, value: Double) -> Double
    }

    final class PercentRecallProfileAdjuster: RecallProfileStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RecallProfile, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapRecallProfileAdjuster: RecallProfileStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RecallProfile, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingRecallProfileAdjuster: RecallProfileStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RecallProfile, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumRecallProfileAdjuster: RecallProfileStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RecallProfile, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the recall profile steps in order and keeps a trace of each.
    final class RecallProfileEngine {
        var steps: [any RecallProfileStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RecallProfileStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RecallProfile) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RecallProfileStep = steps[index]
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

        func evaluateAll(_ items: [RecallProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRecallProfileEngine() -> RecallProfileEngine {
        return RecallProfileEngine(
            steps: [
                PercentRecallProfileAdjuster(percent: 12.0),
                CapRecallProfileAdjuster(cap: 41822.0),
                RoundingRecallProfileAdjuster(step: 0.05),
                MinimumRecallProfileAdjuster(minimum: 37.2),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 25117.7
        )
    }
}
