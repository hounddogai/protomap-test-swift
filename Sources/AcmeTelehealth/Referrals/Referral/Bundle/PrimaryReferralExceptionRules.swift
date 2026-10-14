import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a primary referral exception must pass. Check returns its problems, or none.
    protocol PrimaryReferralExceptionRule {
        func check(_ item: PrimaryReferralException) -> [String]
    }

    final class PrimaryReferralExceptionTitleLengthRule: PrimaryReferralExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryReferralException) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryReferralExceptionRequiredCodeRule: PrimaryReferralExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryReferralException) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryReferralExceptionTimezoneLengthRule: PrimaryReferralExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryReferralException) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryReferralExceptionRequiredEncounterIDRule: PrimaryReferralExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryReferralException) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryReferralExceptionAllowedEncounterIDRule: PrimaryReferralExceptionRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryReferralException) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.encounterID)) {
                return ["encounter id \(item.encounterID) is inconsistent"]
            }
            return []
        }
    }

    final class PrimaryReferralExceptionRequiredTitleRule: PrimaryReferralExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryReferralException) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a primary referral exception.
    final class PrimaryReferralExceptionValidator {
        var rules: [any PrimaryReferralExceptionRule]

        init(rules: [any PrimaryReferralExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryReferralException) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryReferralException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryReferralException]) -> [String: [String]] {
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

    static func defaultPrimaryReferralExceptionValidator() -> PrimaryReferralExceptionValidator {
        return PrimaryReferralExceptionValidator(
            rules: [
                PrimaryReferralExceptionTitleLengthRule(maxLength: 3600),
                PrimaryReferralExceptionRequiredCodeRule(message: "primary referral exception needs a value"),
                PrimaryReferralExceptionTimezoneLengthRule(maxLength: 86400),
                PrimaryReferralExceptionRequiredEncounterIDRule(
                    message: "primary referral exception needs this field"
                ),
                PrimaryReferralExceptionAllowedEncounterIDRule(allowed: []),
                PrimaryReferralExceptionRequiredTitleRule(message: "primary referral exception needs an entry"),
            ]
        )
    }
}
