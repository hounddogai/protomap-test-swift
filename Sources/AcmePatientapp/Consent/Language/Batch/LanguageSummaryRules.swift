import AcmePlatform
import Foundation

extension Consent {
    /// A rule a language summary must pass. Check returns its problems, or none.
    protocol LanguageSummaryRule {
        func check(_ item: LanguageSummary) -> [String]
    }

    final class LanguageSummaryRequiredTitleRule: LanguageSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LanguageSummary) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LanguageSummaryAllowedChecksumRule: LanguageSummaryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LanguageSummary) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.checksum)) {
                return ["checksum \(item.checksum) is out of range"]
            }
            return []
        }
    }

    final class LanguageSummaryRequiredBedRule: LanguageSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LanguageSummary) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LanguageSummaryCodePrefixRule: LanguageSummaryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LanguageSummary) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a language summary.
    final class LanguageSummaryValidator {
        var rules: [any LanguageSummaryRule]

        init(rules: [any LanguageSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: LanguageSummary) -> [String] {
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

        func requireValid(_ item: LanguageSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LanguageSummary]) -> [String: [String]] {
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

    static func defaultLanguageSummaryValidator() -> LanguageSummaryValidator {
        return LanguageSummaryValidator(
            rules: [
                LanguageSummaryRequiredTitleRule(message: "language summary needs a value"),
                LanguageSummaryAllowedChecksumRule(allowed: ["adaptive", "seasonal"]),
                LanguageSummaryRequiredBedRule(message: "language summary needs this field"),
                LanguageSummaryCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
