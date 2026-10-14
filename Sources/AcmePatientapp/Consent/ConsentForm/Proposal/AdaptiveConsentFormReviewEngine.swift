import AcmePlatform
import Foundation

extension Consent {
    /// One step of the adaptive consent form review calculation.
    protocol AdaptiveConsentFormReviewFactor {
        func describe() -> String
        func adjust(_ item: AdaptiveConsentFormReview, value: Double) -> Double
    }

    final class RoundingAdaptiveConsentFormReviewAdjuster: AdaptiveConsentFormReviewFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveConsentFormReview, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentAdaptiveConsentFormReviewAdjuster: AdaptiveConsentFormReviewFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveConsentFormReview, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameAdaptiveConsentFormReviewAdjuster: AdaptiveConsentFormReviewFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: AdaptiveConsentFormReview, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the adaptive consent form review steps in order and keeps a trace of each.
    final class AdaptiveConsentFormReviewEngine {
        var steps: [any AdaptiveConsentFormReviewFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveConsentFormReviewFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: AdaptiveConsentFormReview) -> Double {
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

        func evaluateAll(_ items: [AdaptiveConsentFormReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultAdaptiveConsentFormReviewEngine() -> AdaptiveConsentFormReviewEngine {
        return AdaptiveConsentFormReviewEngine(
            steps: [
                RoundingAdaptiveConsentFormReviewAdjuster(step: 0.05),
                PercentAdaptiveConsentFormReviewAdjuster(percent: 19.6),
                NameAdaptiveConsentFormReviewAdjuster(factors: ["retail": 0.95, "north": 0.72]),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 9875.7
        )
    }
}
