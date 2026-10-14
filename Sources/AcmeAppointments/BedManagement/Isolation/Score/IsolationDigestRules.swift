import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a isolation digest must pass. Check returns its problems, or none.
    protocol IsolationDigestRule {
        func check(_ item: IsolationDigest) -> [String]
    }

    final class IsolationDigestTagsLimitRule: IsolationDigestRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: IsolationDigest) -> [String] {
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

    final class IsolationDigestRequiredCodeRule: IsolationDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: IsolationDigest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class IsolationDigestRequiredLocaleRule: IsolationDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: IsolationDigest) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class IsolationDigestCodePrefixRule: IsolationDigestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: IsolationDigest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class IsolationDigestRequiredLabelRule: IsolationDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: IsolationDigest) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a isolation digest.
    final class IsolationDigestValidator {
        var rules: [any IsolationDigestRule]

        init(rules: [any IsolationDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: IsolationDigest) -> [String] {
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

        func requireValid(_ item: IsolationDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [IsolationDigest]) -> [String: [String]] {
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

    static func defaultIsolationDigestValidator() -> IsolationDigestValidator {
        return IsolationDigestValidator(
            rules: [
                IsolationDigestTagsLimitRule(maxCount: 120, banned: ["primary", "pending"]),
                IsolationDigestRequiredCodeRule(message: "isolation digest needs this field"),
                IsolationDigestRequiredLocaleRule(message: "isolation digest needs an entry"),
                IsolationDigestCodePrefixRule(prefix: "REF"),
                IsolationDigestRequiredLabelRule(message: "isolation digest needs a value"),
            ]
        )
    }
}
