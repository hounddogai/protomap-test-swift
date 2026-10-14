import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the referral score calculation.
    protocol ReferralScoreFactor {
        func describe() -> String
        func adjust(_ item: ReferralScore, value: Double) -> Double
    }

    final class ReferralScoreRevisionOffsetAdjuster: ReferralScoreFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus revision times \(weight)"
        }

        func adjust(_ item: ReferralScore, value: Double) -> Double {
            return value + Double(item.revision) * weight
        }
    }

    final class PercentReferralScoreAdjuster: ReferralScoreFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ReferralScore, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumReferralScoreAdjuster: ReferralScoreFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ReferralScore, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the referral score steps in order and keeps a trace of each.
    final class ReferralScoreEngine {
        var steps: [any ReferralScoreFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReferralScoreFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ReferralScore) -> Double {
            var current = item.projectedExposure()
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

        func evaluateAll(_ items: [ReferralScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultReferralScoreEngine() -> ReferralScoreEngine {
        return ReferralScoreEngine(
            steps: [
                ReferralScoreRevisionOffsetAdjuster(weight: 1.09),
                PercentReferralScoreAdjuster(percent: 21.7),
                MinimumReferralScoreAdjuster(minimum: 5.9),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 93389.6
        )
    }
}
