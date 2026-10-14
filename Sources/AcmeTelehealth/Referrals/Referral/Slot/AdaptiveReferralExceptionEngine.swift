import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the adaptive referral exception calculation.
    protocol AdaptiveReferralExceptionStep {
        func describe() -> String
        func adjust(_ item: AdaptiveReferralException, value: Double) -> Double
    }

    final class TieredAdaptiveReferralExceptionAdjuster: AdaptiveReferralExceptionStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveReferralException, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumAdaptiveReferralExceptionAdjuster: AdaptiveReferralExceptionStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveReferralException, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentAdaptiveReferralExceptionAdjuster: AdaptiveReferralExceptionStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveReferralException, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the adaptive referral exception steps in order and keeps a trace of each.
    final class AdaptiveReferralExceptionEngine {
        var steps: [any AdaptiveReferralExceptionStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveReferralExceptionStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AdaptiveReferralException) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveReferralExceptionStep = steps[index]
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

        func evaluateAll(_ items: [AdaptiveReferralException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAdaptiveReferralExceptionEngine() -> AdaptiveReferralExceptionEngine {
        return AdaptiveReferralExceptionEngine(
            steps: [
                TieredAdaptiveReferralExceptionAdjuster(bounds: [7354.0, 9304.0], rates: [1.16, 0.85]),
                MinimumAdaptiveReferralExceptionAdjuster(minimum: 16.1),
                PercentAdaptiveReferralExceptionAdjuster(percent: -4.9),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 64404.5
        )
    }
}
