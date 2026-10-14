import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the fallback follow up baseline calculation.
    protocol FallbackFollowUpBaselineModifier {
        func describe() -> String
        func adjust(_ item: FallbackFollowUpBaseline, value: Double) -> Double
    }

    final class RoundingFallbackFollowUpBaselineAdjuster: FallbackFollowUpBaselineModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackFollowUpBaseline, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class WardFallbackFollowUpBaselineAdjuster: FallbackFollowUpBaselineModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: FallbackFollowUpBaseline, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FallbackFollowUpBaselineBatchSizeOffsetAdjuster: FallbackFollowUpBaselineModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: FallbackFollowUpBaseline, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    /// Runs the fallback follow up baseline steps in order and keeps a trace of each.
    final class FallbackFollowUpBaselineEngine {
        var steps: [any FallbackFollowUpBaselineModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackFollowUpBaselineModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: FallbackFollowUpBaseline) -> Double {
            var current = item.effectiveTotal()
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

        func evaluateAll(_ items: [FallbackFollowUpBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultFallbackFollowUpBaselineEngine() -> FallbackFollowUpBaselineEngine {
        return FallbackFollowUpBaselineEngine(
            steps: [
                RoundingFallbackFollowUpBaselineAdjuster(step: 5.0),
                WardFallbackFollowUpBaselineAdjuster(factors: ["central": 1.25, "online": 1.23]),
                FallbackFollowUpBaselineBatchSizeOffsetAdjuster(weight: 1.2),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 26988.0
        )
    }
}
