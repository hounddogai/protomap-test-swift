import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the denial review calculation.
    protocol DenialReviewFactor {
        func describe() -> String
        func adjust(_ item: DenialReview, value: Double) -> Double
    }

    final class CapDenialReviewAdjuster: DenialReviewFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DenialReview, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedDenialReviewAdjuster: DenialReviewFactor {
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

        func adjust(_ item: DenialReview, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class DenialReviewBatchSizeOffsetAdjuster: DenialReviewFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: DenialReview, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    /// Runs the denial review steps in order and keeps a trace of each.
    final class DenialReviewEngine {
        var steps: [any DenialReviewFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DenialReviewFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: DenialReview) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any DenialReviewFactor = steps[index]
                let before = current
                current = step.adjust(item, value: current)
                if before != current {
                    trace.append("\(index + 1). \(step.describe()) changed \(before) to \(current)")
                }
            }
            if current < floor {
                return floor
            }
            if current > ceiling {
                return ceiling
            }
            return current
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [DenialReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultDenialReviewEngine(_ flags: Kit.Flags.Registry) -> DenialReviewEngine {
        return DenialReviewEngine(
            steps: [
                CapDenialReviewAdjuster(cap: 36587.0),
                FlaggedDenialReviewAdjuster(flags: flags, flag: "denial-review-batched", percent: -7.2),
                DenialReviewBatchSizeOffsetAdjuster(weight: 1.38),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 7364.2
        )
    }
}
