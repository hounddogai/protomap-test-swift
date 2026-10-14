import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the rolling referral score calculation.
    protocol RollingReferralScoreStep {
        func describe() -> String
        func adjust(_ item: RollingReferralScore, value: Double) -> Double
    }

    final class CapRollingReferralScoreAdjuster: RollingReferralScoreStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingReferralScore, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentRollingReferralScoreAdjuster: RollingReferralScoreStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingReferralScore, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingRollingReferralScoreAdjuster: RollingReferralScoreStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingReferralScore, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the rolling referral score steps in order and keeps a trace of each.
    final class RollingReferralScoreEngine {
        var steps: [any RollingReferralScoreStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingReferralScoreStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RollingReferralScore) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [RollingReferralScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRollingReferralScoreEngine() -> RollingReferralScoreEngine {
        return RollingReferralScoreEngine(
            steps: [
                CapRollingReferralScoreAdjuster(cap: 49666.0),
                PercentRollingReferralScoreAdjuster(percent: -15.4),
                RoundingRollingReferralScoreAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 88987.7
        )
    }
}
