import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the tiered slot review calculation.
    protocol TieredSlotReviewAdjuster {
        func describe() -> String
        func adjust(_ item: TieredSlotReview, value: Double) -> Double
    }

    final class TieredSlotReviewBudgetOffsetAdjuster: TieredSlotReviewAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: TieredSlotReview, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    final class CapTieredSlotReviewAdjuster: TieredSlotReviewAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredSlotReview, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumTieredSlotReviewAdjuster: TieredSlotReviewAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredSlotReview, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingTieredSlotReviewAdjuster: TieredSlotReviewAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredSlotReview, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TitleTieredSlotReviewAdjuster: TieredSlotReviewAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: TieredSlotReview, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the tiered slot review steps in order and keeps a trace of each.
    final class TieredSlotReviewEngine {
        var steps: [any TieredSlotReviewAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredSlotReviewAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: TieredSlotReview) -> Double {
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

        func evaluateAll(_ items: [TieredSlotReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultTieredSlotReviewEngine() -> TieredSlotReviewEngine {
        return TieredSlotReviewEngine(
            steps: [
                TieredSlotReviewBudgetOffsetAdjuster(weight: 0.86),
                CapTieredSlotReviewAdjuster(cap: 21332.0),
                MinimumTieredSlotReviewAdjuster(minimum: 19.6),
                RoundingTieredSlotReviewAdjuster(step: 5.0),
                TitleTieredSlotReviewAdjuster(factors: ["retail": 1.15]),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 89549.2
        )
    }
}
