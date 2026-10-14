import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the batched care protocol review calculation.
    protocol BatchedCareProtocolReviewFactor {
        func describe() -> String
        func adjust(_ item: BatchedCareProtocolReview, value: Double) -> Double
    }

    final class FlaggedBatchedCareProtocolReviewAdjuster: BatchedCareProtocolReviewFactor {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: BatchedCareProtocolReview, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentBatchedCareProtocolReviewAdjuster: BatchedCareProtocolReviewFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedCareProtocolReview, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingBatchedCareProtocolReviewAdjuster: BatchedCareProtocolReviewFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedCareProtocolReview, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TitleBatchedCareProtocolReviewAdjuster: BatchedCareProtocolReviewFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: BatchedCareProtocolReview, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the batched care protocol review steps in order and keeps a trace of each.
    final class BatchedCareProtocolReviewEngine {
        var steps: [any BatchedCareProtocolReviewFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedCareProtocolReviewFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: BatchedCareProtocolReview) -> Double {
            var current = item.projectedTotal()
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

        func evaluateAll(_ items: [BatchedCareProtocolReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultBatchedCareProtocolReviewEngine(_ flags: Kit.Flags.Registry) -> BatchedCareProtocolReviewEngine {
        return BatchedCareProtocolReviewEngine(
            steps: [
                FlaggedBatchedCareProtocolReviewAdjuster(
                    flags: flags,
                    flag: "batched-care-protocol-review-capped",
                    percent: 8.2
                ),
                PercentBatchedCareProtocolReviewAdjuster(percent: -9.5),
                RoundingBatchedCareProtocolReviewAdjuster(step: 0.05),
                TitleBatchedCareProtocolReviewAdjuster(factors: ["west": 0.71, "south": 1.12]),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 39985.6
        )
    }
}
