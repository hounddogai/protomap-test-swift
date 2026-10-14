import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a rolling referral score must pass. Check returns its problems, or none.
    protocol RollingReferralScoreRule {
        func check(_ item: RollingReferralScore) -> [String]
    }

    final class RollingReferralScoreTitleLengthRule: RollingReferralScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingReferralScore) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingReferralScoreAllowedDescriptionRule: RollingReferralScoreRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingReferralScore) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.description)) {
                return ["description \(item.description) is not allowed"]
            }
            return []
        }
    }

    final class RollingReferralScoreRequiredTitleRule: RollingReferralScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingReferralScore) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingReferralScoreCodeLengthRule: RollingReferralScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingReferralScore) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingReferralScoreRequiredLabelRule: RollingReferralScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingReferralScore) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rolling referral score.
    final class RollingReferralScoreValidator {
        var rules: [any RollingReferralScoreRule]

        init(rules: [any RollingReferralScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingReferralScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                let found = rule.check(item)
                if found.count == 0 {
                    continue
                }
                for problem in found {
                    problems.append("\(item.code): \(problem)")
                }
            }
            return problems
        }

        func requireValid(_ item: RollingReferralScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingReferralScore]) -> [String: [String]] {
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

    static func defaultRollingReferralScoreValidator() -> RollingReferralScoreValidator {
        return RollingReferralScoreValidator(
            rules: [
                RollingReferralScoreTitleLengthRule(maxLength: 120),
                RollingReferralScoreAllowedDescriptionRule(allowed: ["pending", "batched", "legacy"]),
                RollingReferralScoreRequiredTitleRule(message: "rolling referral score needs this field"),
                RollingReferralScoreCodeLengthRule(maxLength: 80),
                RollingReferralScoreRequiredLabelRule(message: "rolling referral score needs this field"),
            ]
        )
    }
}
