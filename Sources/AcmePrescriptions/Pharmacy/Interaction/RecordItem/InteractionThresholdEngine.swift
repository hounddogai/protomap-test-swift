import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the interaction threshold calculation.
    protocol InteractionThresholdStep {
        func describe() -> String
        func adjust(_ item: InteractionThreshold, value: Double) -> Double
    }

    final class InteractionThresholdMaximumOffsetAdjuster: InteractionThresholdStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus maximum times \(weight)"
        }

        func adjust(_ item: InteractionThreshold, value: Double) -> Double {
            return value + item.maximum * weight
        }
    }

    final class MinimumInteractionThresholdAdjuster: InteractionThresholdStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: InteractionThreshold, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapInteractionThresholdAdjuster: InteractionThresholdStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: InteractionThreshold, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the interaction threshold steps in order and keeps a trace of each.
    final class InteractionThresholdEngine {
        var steps: [any InteractionThresholdStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InteractionThresholdStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: InteractionThreshold) -> Double {
            var current = item.adjustedTotal()
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

        func evaluateAll(_ items: [InteractionThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultInteractionThresholdEngine() -> InteractionThresholdEngine {
        return InteractionThresholdEngine(
            steps: [
                InteractionThresholdMaximumOffsetAdjuster(weight: 0.41),
                MinimumInteractionThresholdAdjuster(minimum: 14.2),
                CapInteractionThresholdAdjuster(cap: 40995.0),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 21373.3
        )
    }
}
