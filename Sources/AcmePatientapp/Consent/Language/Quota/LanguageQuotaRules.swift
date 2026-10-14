import AcmePlatform
import Foundation

extension Consent {
    /// A rule a language quota must pass. Check returns its problems, or none.
    protocol LanguageQuotaRule {
        func check(_ item: LanguageQuota) -> [String]
    }

    final class LanguageQuotaCodePrefixRule: LanguageQuotaRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LanguageQuota) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LanguageQuotaCodeLengthRule: LanguageQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LanguageQuota) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LanguageQuotaAllowedTitleRule: LanguageQuotaRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LanguageQuota) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is out of range"]
            }
            return []
        }
    }

    /// Runs every rule of a language quota.
    final class LanguageQuotaValidator {
        var rules: [any LanguageQuotaRule]

        init(rules: [any LanguageQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: LanguageQuota) -> [String] {
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

        func requireValid(_ item: LanguageQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LanguageQuota]) -> [String: [String]] {
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

    static func defaultLanguageQuotaValidator() -> LanguageQuotaValidator {
        return LanguageQuotaValidator(
            rules: [
                LanguageQuotaCodePrefixRule(prefix: "Q"),
                LanguageQuotaCodeLengthRule(maxLength: 255),
                LanguageQuotaAllowedTitleRule(allowed: ["scheduled", "weighted"]),
            ]
        )
    }
}
