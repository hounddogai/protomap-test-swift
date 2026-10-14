import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the pending claim review calculation.
    protocol PendingClaimReviewAdjuster {
        func describe() -> String
        func adjust(_ item: PendingClaimReview, value: Double) -> Double
    }

    final class FlaggedPendingClaimReviewAdjuster: PendingClaimReviewAdjuster {
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

        func adjust(_ item: PendingClaimReview, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentPendingClaimReviewAdjuster: PendingClaimReviewAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingClaimReview, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapPendingClaimReviewAdjuster: PendingClaimReviewAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingClaimReview, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the pending claim review steps in order and keeps a trace of each.
    final class PendingClaimReviewEngine {
        var steps: [any PendingClaimReviewAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingClaimReviewAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PendingClaimReview) -> Double {
            var current = item.weightedTotal()
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

        func evaluateAll(_ items: [PendingClaimReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPendingClaimReviewEngine(_ flags: Kit.Flags.Registry) -> PendingClaimReviewEngine {
        return PendingClaimReviewEngine(
            steps: [
                FlaggedPendingClaimReviewAdjuster(flags: flags, flag: "pending-claim-review-regional", percent: -1.4),
                PercentPendingClaimReviewAdjuster(percent: -21.1),
                CapPendingClaimReviewAdjuster(cap: 7053.0),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 51279.3
        )
    }
}
