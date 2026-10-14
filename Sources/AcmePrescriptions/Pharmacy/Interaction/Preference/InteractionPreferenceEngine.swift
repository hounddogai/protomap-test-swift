import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the interaction preference calculation.
    protocol InteractionPreferenceStep {
        func describe() -> String
        func adjust(_ item: InteractionPreference, value: Double) -> Double
    }

    final class MinimumInteractionPreferenceAdjuster: InteractionPreferenceStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: InteractionPreference, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapInteractionPreferenceAdjuster: InteractionPreferenceStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: InteractionPreference, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingInteractionPreferenceAdjuster: InteractionPreferenceStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: InteractionPreference, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the interaction preference steps in order and keeps a trace of each.
    final class InteractionPreferenceEngine {
        var steps: [any InteractionPreferenceStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InteractionPreferenceStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: InteractionPreference) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any InteractionPreferenceStep = steps[index]
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

        func evaluateAll(_ items: [InteractionPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultInteractionPreferenceEngine() -> InteractionPreferenceEngine {
        return InteractionPreferenceEngine(
            steps: [
                MinimumInteractionPreferenceAdjuster(minimum: 26.4),
                CapInteractionPreferenceAdjuster(cap: 13391.0),
                RoundingInteractionPreferenceAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 38563.2
        )
    }
}
