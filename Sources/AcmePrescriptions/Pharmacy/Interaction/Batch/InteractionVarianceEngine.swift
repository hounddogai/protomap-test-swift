import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the interaction variance calculation.
    protocol InteractionVarianceFactor {
        func describe() -> String
        func adjust(_ item: InteractionVariance, value: Double) -> Double
    }

    final class InteractionVarianceRevisionOffsetAdjuster: InteractionVarianceFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus revision times \(weight)"
        }

        func adjust(_ item: InteractionVariance, value: Double) -> Double {
            return value + Double(item.revision) * weight
        }
    }

    final class MinimumInteractionVarianceAdjuster: InteractionVarianceFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: InteractionVariance, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TitleInteractionVarianceAdjuster: InteractionVarianceFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: InteractionVariance, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingInteractionVarianceAdjuster: InteractionVarianceFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: InteractionVariance, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the interaction variance steps in order and keeps a trace of each.
    final class InteractionVarianceEngine {
        var steps: [any InteractionVarianceFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InteractionVarianceFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: InteractionVariance) -> Double {
            var current = item.netValue()
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

        func evaluateAll(_ items: [InteractionVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultInteractionVarianceEngine() -> InteractionVarianceEngine {
        return InteractionVarianceEngine(
            steps: [
                InteractionVarianceRevisionOffsetAdjuster(weight: 0.11),
                MinimumInteractionVarianceAdjuster(minimum: 14.3),
                TitleInteractionVarianceAdjuster(factors: ["online": 1.13, "retail": 0.98, "east": 1.32]),
                RoundingInteractionVarianceAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 96992.9
        )
    }
}
