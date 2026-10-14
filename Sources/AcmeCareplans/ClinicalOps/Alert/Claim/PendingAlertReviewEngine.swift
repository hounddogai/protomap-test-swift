import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the pending alert review calculation.
    protocol PendingAlertReviewStep {
        func describe() -> String
        func adjust(_ item: PendingAlertReview, value: Double) -> Double
    }

    final class TieredPendingAlertReviewAdjuster: PendingAlertReviewStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingAlertReview, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentPendingAlertReviewAdjuster: PendingAlertReviewStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingAlertReview, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedPendingAlertReviewAdjuster: PendingAlertReviewStep {
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

        func adjust(_ item: PendingAlertReview, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the pending alert review steps in order and keeps a trace of each.
    final class PendingAlertReviewEngine {
        var steps: [any PendingAlertReviewStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingAlertReviewStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PendingAlertReview) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingAlertReviewStep = steps[index]
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

        func evaluateAll(_ items: [PendingAlertReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPendingAlertReviewEngine(_ flags: Kit.Flags.Registry) -> PendingAlertReviewEngine {
        return PendingAlertReviewEngine(
            steps: [
                TieredPendingAlertReviewAdjuster(bounds: [111.0, 5393.0, 7233.0], rates: [0.97, 1.03, 1.14]),
                PercentPendingAlertReviewAdjuster(percent: 10.8),
                FlaggedPendingAlertReviewAdjuster(flags: flags, flag: "pending-alert-review-strict", percent: 6.0),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 25734.3
        )
    }
}
