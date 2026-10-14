import AcmePlatform
import Foundation

extension Consent {
    /// One step of the scheduled consent form review calculation.
    protocol ScheduledConsentFormReviewAdjuster {
        func describe() -> String
        func adjust(_ item: ScheduledConsentFormReview, value: Double) -> Double
    }

    final class ScheduledConsentFormReviewCostOffsetAdjuster: ScheduledConsentFormReviewAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: ScheduledConsentFormReview, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    final class PercentScheduledConsentFormReviewAdjuster: ScheduledConsentFormReviewAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledConsentFormReview, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameScheduledConsentFormReviewAdjuster: ScheduledConsentFormReviewAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: ScheduledConsentFormReview, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the scheduled consent form review steps in order and keeps a trace of each.
    final class ScheduledConsentFormReviewEngine {
        var steps: [any ScheduledConsentFormReviewAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledConsentFormReviewAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ScheduledConsentFormReview) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledConsentFormReviewAdjuster = steps[index]
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

        func evaluateAll(_ items: [ScheduledConsentFormReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultScheduledConsentFormReviewEngine() -> ScheduledConsentFormReviewEngine {
        return ScheduledConsentFormReviewEngine(
            steps: [
                ScheduledConsentFormReviewCostOffsetAdjuster(weight: 0.84),
                PercentScheduledConsentFormReviewAdjuster(percent: 15.5),
                NameScheduledConsentFormReviewAdjuster(factors: ["central": 0.98, "online": 0.99, "south": 1.19]),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 23086.8
        )
    }
}
