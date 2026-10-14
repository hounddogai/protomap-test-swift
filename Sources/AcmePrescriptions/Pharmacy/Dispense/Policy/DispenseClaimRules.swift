import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a dispense claim must pass. Check returns its problems, or none.
    protocol DispenseClaimRule {
        func check(_ item: DispenseClaim) -> [String]
    }

    final class DispenseClaimRequiredCodeRule: DispenseClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DispenseClaim) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DispenseClaimCodePrefixRule: DispenseClaimRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DispenseClaim) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DispenseClaimTitleLengthRule: DispenseClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DispenseClaim) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DispenseClaimTagsLimitRule: DispenseClaimRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: DispenseClaim) -> [String] {
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

    final class DispenseClaimAllowedCodeRule: DispenseClaimRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DispenseClaim) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is blocked"]
            }
            return []
        }
    }

    /// Runs every rule of a dispense claim.
    final class DispenseClaimValidator {
        var rules: [any DispenseClaimRule]

        init(rules: [any DispenseClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: DispenseClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DispenseClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DispenseClaim]) -> [String: [String]] {
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

    static func defaultDispenseClaimValidator() -> DispenseClaimValidator {
        return DispenseClaimValidator(
            rules: [
                DispenseClaimRequiredCodeRule(message: "dispense claim needs a value"),
                DispenseClaimCodePrefixRule(prefix: "Q"),
                DispenseClaimTitleLengthRule(maxLength: 64),
                DispenseClaimTagsLimitRule(maxCount: 64, banned: ["batched", "scheduled", "lenient"]),
                DispenseClaimAllowedCodeRule(allowed: []),
            ]
        )
    }
}
