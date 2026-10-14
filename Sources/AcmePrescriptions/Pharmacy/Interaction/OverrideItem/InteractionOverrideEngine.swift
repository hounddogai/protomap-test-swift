import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the interaction override calculation.
    protocol InteractionOverrideModifier {
        func describe() -> String
        func adjust(_ item: InteractionOverride, value: Double) -> Double
    }

    final class PercentInteractionOverrideAdjuster: InteractionOverrideModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: InteractionOverride, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumInteractionOverrideAdjuster: InteractionOverrideModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: InteractionOverride, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingInteractionOverrideAdjuster: InteractionOverrideModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: InteractionOverride, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class InteractionOverrideSequenceOffsetAdjuster: InteractionOverrideModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: InteractionOverride, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    /// Runs the interaction override steps in order and keeps a trace of each.
    final class InteractionOverrideEngine {
        var steps: [any InteractionOverrideModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InteractionOverrideModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: InteractionOverride) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [InteractionOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultInteractionOverrideEngine() -> InteractionOverrideEngine {
        return InteractionOverrideEngine(
            steps: [
                PercentInteractionOverrideAdjuster(percent: -4.0),
                MinimumInteractionOverrideAdjuster(minimum: 18.6),
                RoundingInteractionOverrideAdjuster(step: 0.1),
                InteractionOverrideSequenceOffsetAdjuster(weight: 1.83),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 14523.7
        )
    }
}
