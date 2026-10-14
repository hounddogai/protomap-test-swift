import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the slot draft calculation.
    protocol SlotDraftStep {
        func describe() -> String
        func adjust(_ item: SlotDraft, value: Double) -> Double
    }

    final class RoundingSlotDraftAdjuster: SlotDraftStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SlotDraft, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumSlotDraftAdjuster: SlotDraftStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SlotDraft, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LocaleSlotDraftAdjuster: SlotDraftStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: SlotDraft, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the slot draft steps in order and keeps a trace of each.
    final class SlotDraftEngine {
        var steps: [any SlotDraftStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SlotDraftStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: SlotDraft) -> Double {
            var current = item.weightedExposure()
            trace = []
            for step in steps {
                let next = step.adjust(item, value: current)
                trace.append("\(step.describe()): \((current * 100).rounded() / 100) -> \((next * 100).rounded() / 100)")
                current = next
            }
            return Kit.Numbers.clampFloat(current, low: floor, high: ceiling)
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [SlotDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultSlotDraftEngine() -> SlotDraftEngine {
        return SlotDraftEngine(
            steps: [
                RoundingSlotDraftAdjuster(step: 1.0),
                MinimumSlotDraftAdjuster(minimum: 13.3),
                LocaleSlotDraftAdjuster(factors: ["retail": 1.11, "online": 0.71, "north": 1.2]),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 96356.3
        )
    }
}
