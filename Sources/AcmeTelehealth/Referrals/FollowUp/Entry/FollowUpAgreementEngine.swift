import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the follow up agreement calculation.
    protocol FollowUpAgreementFactor {
        func describe() -> String
        func adjust(_ item: FollowUpAgreement, value: Double) -> Double
    }

    final class MinimumFollowUpAgreementAdjuster: FollowUpAgreementFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FollowUpAgreement, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentFollowUpAgreementAdjuster: FollowUpAgreementFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FollowUpAgreement, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingFollowUpAgreementAdjuster: FollowUpAgreementFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FollowUpAgreement, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedFollowUpAgreementAdjuster: FollowUpAgreementFactor {
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

        func adjust(_ item: FollowUpAgreement, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the follow up agreement steps in order and keeps a trace of each.
    final class FollowUpAgreementEngine {
        var steps: [any FollowUpAgreementFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FollowUpAgreementFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: FollowUpAgreement) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any FollowUpAgreementFactor = steps[index]
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

        func evaluateAll(_ items: [FollowUpAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultFollowUpAgreementEngine(_ flags: Kit.Flags.Registry) -> FollowUpAgreementEngine {
        return FollowUpAgreementEngine(
            steps: [
                MinimumFollowUpAgreementAdjuster(minimum: 25.4),
                PercentFollowUpAgreementAdjuster(percent: 8.4),
                RoundingFollowUpAgreementAdjuster(step: 0.5),
                FlaggedFollowUpAgreementAdjuster(flags: flags, flag: "follow-up-agreement-lenient", percent: 4.5),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 36583.3
        )
    }
}
