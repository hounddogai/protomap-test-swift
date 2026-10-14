import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the slot score calculation.
    protocol SlotScoreFactor {
        func describe() -> String
        func adjust(_ item: SlotScore, value: Double) -> Double
    }

    final class SlotScoreDurationMinutesOffsetAdjuster: SlotScoreFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus duration minutes times \(weight)"
        }

        func adjust(_ item: SlotScore, value: Double) -> Double {
            return value + Double(item.durationMinutes) * weight
        }
    }

    final class MinimumSlotScoreAdjuster: SlotScoreFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SlotScore, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentSlotScoreAdjuster: SlotScoreFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SlotScore, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingSlotScoreAdjuster: SlotScoreFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SlotScore, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the slot score steps in order and keeps a trace of each.
    final class SlotScoreEngine {
        var steps: [any SlotScoreFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SlotScoreFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SlotScore) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any SlotScoreFactor = steps[index]
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

        func evaluateAll(_ items: [SlotScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSlotScoreEngine() -> SlotScoreEngine {
        return SlotScoreEngine(
            steps: [
                SlotScoreDurationMinutesOffsetAdjuster(weight: 0.64),
                MinimumSlotScoreAdjuster(minimum: 48.7),
                PercentSlotScoreAdjuster(percent: -19.2),
                RoundingSlotScoreAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 10262.2
        )
    }
}
