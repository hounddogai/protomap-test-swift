import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a referral score must pass. Check returns its problems, or none.
    protocol ReferralScoreRule {
        func check(_ item: ReferralScore) -> [String]
    }

    final class ReferralScoreRequiredLabelRule: ReferralScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferralScore) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferralScoreRequiredWardRule: ReferralScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferralScore) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferralScoreAllowedCodeRule: ReferralScoreRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ReferralScore) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is above maximum"]
            }
            return []
        }
    }

    final class ReferralScoreLabelLengthRule: ReferralScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferralScore) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferralScoreClinicianIDLengthRule: ReferralScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferralScore) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferralScoreRequiredClinicianIDRule: ReferralScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferralScore) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a referral score.
    final class ReferralScoreValidator {
        var rules: [any ReferralScoreRule]

        init(rules: [any ReferralScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferralScore) -> [String] {
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

        func requireValid(_ item: ReferralScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferralScore]) -> [String: [String]] {
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

    static func defaultReferralScoreValidator() -> ReferralScoreValidator {
        return ReferralScoreValidator(
            rules: [
                ReferralScoreRequiredLabelRule(message: "referral score needs this field"),
                ReferralScoreRequiredWardRule(message: "referral score needs an entry"),
                ReferralScoreAllowedCodeRule(allowed: ["manual", "default"]),
                ReferralScoreLabelLengthRule(maxLength: 80),
                ReferralScoreClinicianIDLengthRule(maxLength: 120),
                ReferralScoreRequiredClinicianIDRule(message: "referral score needs this field"),
            ]
        )
    }
}
