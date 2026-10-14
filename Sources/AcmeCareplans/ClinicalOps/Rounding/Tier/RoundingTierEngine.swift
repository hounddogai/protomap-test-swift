import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the rounding tier calculation.
    protocol RoundingTierModifier {
        func describe() -> String
        func adjust(_ item: RoundingTier, value: Double) -> Double
    }

    final class RoundingRoundingTierAdjuster: RoundingTierModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RoundingTier, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class SourceRoundingTierAdjuster: RoundingTierModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: RoundingTier, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumRoundingTierAdjuster: RoundingTierModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RoundingTier, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the rounding tier steps in order and keeps a trace of each.
    final class RoundingTierEngine {
        var steps: [any RoundingTierModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RoundingTierModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RoundingTier) -> Double {
            var current = item.effectiveVolume()
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

        func evaluateAll(_ items: [RoundingTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRoundingTierEngine() -> RoundingTierEngine {
        return RoundingTierEngine(
            steps: [
                RoundingRoundingTierAdjuster(step: 1.0),
                SourceRoundingTierAdjuster(factors: ["west": 1.1, "central": 0.82, "east": 0.86]),
                MinimumRoundingTierAdjuster(minimum: 48.4),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 12099.0
        )
    }
}
