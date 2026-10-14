import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a pending authorization agreement must pass. Check returns its problems, or none.
    protocol PendingAuthorizationAgreementRule {
        func check(_ item: PendingAuthorizationAgreement) -> [String]
    }

    final class PendingAuthorizationAgreementRequiredUnitRule: PendingAuthorizationAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingAuthorizationAgreement) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingAuthorizationAgreementWardLengthRule: PendingAuthorizationAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingAuthorizationAgreement) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingAuthorizationAgreementTitleLengthRule: PendingAuthorizationAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingAuthorizationAgreement) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingAuthorizationAgreementCodePrefixRule: PendingAuthorizationAgreementRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingAuthorizationAgreement) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PendingAuthorizationAgreementRefillsRangeRule: PendingAuthorizationAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingAuthorizationAgreement) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingAuthorizationAgreementTagsLimitRule: PendingAuthorizationAgreementRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: PendingAuthorizationAgreement) -> [String] {
            var problems: [String] = []
            if item.tags.count > maxCount {
                problems.append("has \(item.tags.count) tags, at most \(maxCount) allowed")
            }
            for tag in item.tags {
                if banned.contains(tag) {
                    problems.append("tag \(tag) is not allowed")
                }
            }
            return problems
        }
    }

    /// Runs every rule of a pending authorization agreement.
    final class PendingAuthorizationAgreementValidator {
        var rules: [any PendingAuthorizationAgreementRule]

        init(rules: [any PendingAuthorizationAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingAuthorizationAgreement) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingAuthorizationAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingAuthorizationAgreement]) -> [String: [String]] {
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

    static func defaultPendingAuthorizationAgreementValidator() -> PendingAuthorizationAgreementValidator {
        return PendingAuthorizationAgreementValidator(
            rules: [
                PendingAuthorizationAgreementRequiredUnitRule(
                    message: "pending authorization agreement needs a value"
                ),
                PendingAuthorizationAgreementWardLengthRule(maxLength: 64),
                PendingAuthorizationAgreementTitleLengthRule(maxLength: 32),
                PendingAuthorizationAgreementCodePrefixRule(prefix: "X"),
                PendingAuthorizationAgreementRefillsRangeRule(min: 16, max: 1000),
                PendingAuthorizationAgreementTagsLimitRule(maxCount: 255, banned: []),
            ]
        )
    }
}
