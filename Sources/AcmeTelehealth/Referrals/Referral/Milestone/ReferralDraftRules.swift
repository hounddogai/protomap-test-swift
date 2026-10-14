import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a referral draft must pass. Check returns its problems, or none.
    protocol ReferralDraftRule {
        func check(_ item: ReferralDraft) -> [String]
    }

    final class ReferralDraftRequiredNameRule: ReferralDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferralDraft) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferralDraftSequenceRangeRule: ReferralDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferralDraft) -> [String] {
            let value = item.sequence
            var problems: [String] = []
            if value < min {
                problems.append("sequence \(value) is below \(min)")
            }
            if value > max {
                problems.append("sequence \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ReferralDraftFloorValueRangeRule: ReferralDraftRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferralDraft) -> [String] {
            let value = item.floorValue
            var problems: [String] = []
            if value < min {
                problems.append("floor value \(value) is below \(min)")
            }
            if value > max {
                problems.append("floor value \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ReferralDraftCopayRangeRule: ReferralDraftRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferralDraft) -> [String] {
            let value = item.copay
            var problems: [String] = []
            if value < min {
                problems.append("copay \(value) is below \(min)")
            }
            if value > max {
                problems.append("copay \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a referral draft.
    final class ReferralDraftValidator {
        var rules: [any ReferralDraftRule]

        init(rules: [any ReferralDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferralDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReferralDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferralDraft]) -> [String: [String]] {
            var report: [String: [String]] = [:]
            for item in items {
                let problems = self.validate(item)
                if problems.count > 0 {
                    report[item.code] = problems
                }
            }
            return report
        }
    }

    static func defaultReferralDraftValidator() -> ReferralDraftValidator {
        return ReferralDraftValidator(
            rules: [
                ReferralDraftRequiredNameRule(message: "referral draft needs a value"),
                ReferralDraftSequenceRangeRule(min: 120, max: 1000),
                ReferralDraftFloorValueRangeRule(min: 7.0, max: 1545.5),
                ReferralDraftCopayRangeRule(min: 8.8, max: 370.2),
            ]
        )
    }
}
