import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the interaction target calculation.
    protocol InteractionTargetAdjuster {
        func describe() -> String
        func adjust(_ item: InteractionTarget, value: Double) -> Double
    }

    final class MinimumInteractionTargetAdjuster: InteractionTargetAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: InteractionTarget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredInteractionTargetAdjuster: InteractionTargetAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: InteractionTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingInteractionTargetAdjuster: InteractionTargetAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: InteractionTarget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class NameInteractionTargetAdjuster: InteractionTargetAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: InteractionTarget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentInteractionTargetAdjuster: InteractionTargetAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: InteractionTarget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the interaction target steps in order and keeps a trace of each.
    final class InteractionTargetEngine {
        var steps: [any InteractionTargetAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InteractionTargetAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: InteractionTarget) -> Double {
            var current = item.adjustedVolume()
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

        func evaluateAll(_ items: [InteractionTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultInteractionTargetEngine() -> InteractionTargetEngine {
        return InteractionTargetEngine(
            steps: [
                MinimumInteractionTargetAdjuster(minimum: 42.7),
                TieredInteractionTargetAdjuster(bounds: [1632.0, 5144.0], rates: [1.2, 1.08]),
                RoundingInteractionTargetAdjuster(step: 0.1),
                NameInteractionTargetAdjuster(factors: ["north": 0.87]),
                PercentInteractionTargetAdjuster(percent: 13.0),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 92485.4
        )
    }
}
