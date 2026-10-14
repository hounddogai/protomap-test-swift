import AcmePlatform
import Foundation

extension Labs {
    /// A rule a accession policy must pass. Check returns its problems, or none.
    protocol AccessionPolicyRule {
        func check(_ item: AccessionPolicy) -> [String]
    }

    final class AccessionPolicyRequiredTitleRule: AccessionPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AccessionPolicy) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AccessionPolicyCodePrefixRule: AccessionPolicyRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AccessionPolicy) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AccessionPolicyTagsLimitRule: AccessionPolicyRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: AccessionPolicy) -> [String] {
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

    final class AccessionPolicyRequiredBedRule: AccessionPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AccessionPolicy) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AccessionPolicyCodeLengthRule: AccessionPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AccessionPolicy) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AccessionPolicyRequiredCodeRule: AccessionPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AccessionPolicy) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a accession policy.
    final class AccessionPolicyValidator {
        var rules: [any AccessionPolicyRule]

        init(rules: [any AccessionPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: AccessionPolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AccessionPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AccessionPolicy]) -> [String: [String]] {
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

    static func defaultAccessionPolicyValidator() -> AccessionPolicyValidator {
        return AccessionPolicyValidator(
            rules: [
                AccessionPolicyRequiredTitleRule(message: "accession policy needs an entry"),
                AccessionPolicyCodePrefixRule(prefix: "Q"),
                AccessionPolicyTagsLimitRule(maxCount: 3600, banned: ["batched", "regional"]),
                AccessionPolicyRequiredBedRule(message: "accession policy needs a value"),
                AccessionPolicyCodeLengthRule(maxLength: 80),
                AccessionPolicyRequiredCodeRule(message: "accession policy needs this field"),
            ]
        )
    }
}
