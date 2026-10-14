import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the slot preference calculation.
    protocol SlotPreferenceModifier {
        func describe() -> String
        func adjust(_ item: SlotPreference, value: Double) -> Double
    }

    final class MinimumSlotPreferenceAdjuster: SlotPreferenceModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SlotPreference, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingSlotPreferenceAdjuster: SlotPreferenceModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SlotPreference, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredSlotPreferenceAdjuster: SlotPreferenceModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SlotPreference, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the slot preference steps in order and keeps a trace of each.
    final class SlotPreferenceEngine {
        var steps: [any SlotPreferenceModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SlotPreferenceModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SlotPreference) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any SlotPreferenceModifier = steps[index]
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

        func evaluateAll(_ items: [SlotPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSlotPreferenceEngine() -> SlotPreferenceEngine {
        return SlotPreferenceEngine(
            steps: [
                MinimumSlotPreferenceAdjuster(minimum: 47.1),
                RoundingSlotPreferenceAdjuster(step: 0.25),
                TieredSlotPreferenceAdjuster(bounds: [31.0, 4390.0], rates: [1.13, 1.05]),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 6371.0
        )
    }
}
