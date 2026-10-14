import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the rolling referral exception calculation.
    protocol RollingReferralExceptionModifier {
        func describe() -> String
        func adjust(_ item: RollingReferralException, value: Double) -> Double
    }

    final class MinimumRollingReferralExceptionAdjuster: RollingReferralExceptionModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingReferralException, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentRollingReferralExceptionAdjuster: RollingReferralExceptionModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingReferralException, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapRollingReferralExceptionAdjuster: RollingReferralExceptionModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingReferralException, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingRollingReferralExceptionAdjuster: RollingReferralExceptionModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingReferralException, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class LabelRollingReferralExceptionAdjuster: RollingReferralExceptionModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: RollingReferralException, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the rolling referral exception steps in order and keeps a trace of each.
    final class RollingReferralExceptionEngine {
        var steps: [any RollingReferralExceptionModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingReferralExceptionModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RollingReferralException) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingReferralExceptionModifier = steps[index]
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

        func evaluateAll(_ items: [RollingReferralException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRollingReferralExceptionEngine() -> RollingReferralExceptionEngine {
        return RollingReferralExceptionEngine(
            steps: [
                MinimumRollingReferralExceptionAdjuster(minimum: 30.4),
                PercentRollingReferralExceptionAdjuster(percent: 13.2),
                CapRollingReferralExceptionAdjuster(cap: 9604.0),
                RoundingRollingReferralExceptionAdjuster(step: 1.0),
                LabelRollingReferralExceptionAdjuster(factors: ["central": 1.02]),
            ],
            trace: [],
            floor: 0.0,
            ceiling: 92988.3
        )
    }
}
