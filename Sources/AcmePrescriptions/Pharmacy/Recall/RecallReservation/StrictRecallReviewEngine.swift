import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the strict recall review calculation.
    protocol StrictRecallReviewFactor {
        func describe() -> String
        func adjust(_ item: StrictRecallReview, value: Double) -> Double
    }

    final class PercentStrictRecallReviewAdjuster: StrictRecallReviewFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictRecallReview, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredStrictRecallReviewAdjuster: StrictRecallReviewFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictRecallReview, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class StrictRecallReviewDosageMgOffsetAdjuster: StrictRecallReviewFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: StrictRecallReview, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    final class RoundingStrictRecallReviewAdjuster: StrictRecallReviewFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictRecallReview, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the strict recall review steps in order and keeps a trace of each.
    final class StrictRecallReviewEngine {
        var steps: [any StrictRecallReviewFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictRecallReviewFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: StrictRecallReview) -> Double {
            var current = item.weightedVolume()
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

        func evaluateAll(_ items: [StrictRecallReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultStrictRecallReviewEngine() -> StrictRecallReviewEngine {
        return StrictRecallReviewEngine(
            steps: [
                PercentStrictRecallReviewAdjuster(percent: 9.2),
                TieredStrictRecallReviewAdjuster(bounds: [373.0, 8536.0], rates: [1.11, 0.97]),
                StrictRecallReviewDosageMgOffsetAdjuster(weight: 0.47),
                RoundingStrictRecallReviewAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 91548.1
        )
    }
}
