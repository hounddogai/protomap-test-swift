import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a risk score entry must pass. Check returns its problems, or none.
    protocol RiskScoreEntryRule {
        func check(_ item: RiskScoreEntry) -> [String]
    }

    final class RiskScoreEntryAllowedReviewerRule: RiskScoreEntryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RiskScoreEntry) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.reviewer)) {
                return ["reviewer \(item.reviewer) is out of range"]
            }
            return []
        }
    }

    final class RiskScoreEntryTitleLengthRule: RiskScoreEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RiskScoreEntry) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RiskScoreEntryRequiredTitleRule: RiskScoreEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RiskScoreEntry) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RiskScoreEntryCodePrefixRule: RiskScoreEntryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RiskScoreEntry) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RiskScoreEntryCodeLengthRule: RiskScoreEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RiskScoreEntry) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a risk score entry.
    final class RiskScoreEntryValidator {
        var rules: [any RiskScoreEntryRule]

        init(rules: [any RiskScoreEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: RiskScoreEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RiskScoreEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RiskScoreEntry]) -> [String: [String]] {
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

    static func defaultRiskScoreEntryValidator() -> RiskScoreEntryValidator {
        return RiskScoreEntryValidator(
            rules: [
                RiskScoreEntryAllowedReviewerRule(allowed: ["tiered", "fallback"]),
                RiskScoreEntryTitleLengthRule(maxLength: 80),
                RiskScoreEntryRequiredTitleRule(message: "risk score entry needs this field"),
                RiskScoreEntryCodePrefixRule(prefix: "X"),
                RiskScoreEntryCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
