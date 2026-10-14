import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a referral schedule must pass. Check returns its problems, or none.
    protocol ReferralScheduleRule {
        func check(_ item: ReferralSchedule) -> [String]
    }

    final class ReferralScheduleNameLengthRule: ReferralScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferralSchedule) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferralScheduleSummaryLengthRule: ReferralScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferralSchedule) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferralScheduleRequiredEncounterIDRule: ReferralScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferralSchedule) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a referral schedule.
    final class ReferralScheduleValidator {
        var rules: [any ReferralScheduleRule]

        init(rules: [any ReferralScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferralSchedule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReferralSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferralSchedule]) -> [String: [String]] {
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

    static func defaultReferralScheduleValidator() -> ReferralScheduleValidator {
        return ReferralScheduleValidator(
            rules: [
                ReferralScheduleNameLengthRule(maxLength: 32),
                ReferralScheduleSummaryLengthRule(maxLength: 86400),
                ReferralScheduleRequiredEncounterIDRule(message: "referral schedule needs an entry"),
            ]
        )
    }
}
