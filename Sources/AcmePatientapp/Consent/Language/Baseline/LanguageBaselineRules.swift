import AcmePlatform
import Foundation

extension Consent {
    /// A rule a language baseline must pass. Check returns its problems, or none.
    protocol LanguageBaselineRule {
        func check(_ item: LanguageBaseline) -> [String]
    }

    final class LanguageBaselineRequiredNameRule: LanguageBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LanguageBaseline) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LanguageBaselineCodePrefixRule: LanguageBaselineRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LanguageBaseline) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LanguageBaselineSummaryLengthRule: LanguageBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LanguageBaseline) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LanguageBaselinePatientRefLengthRule: LanguageBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LanguageBaseline) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LanguageBaselineAllowedSummaryRule: LanguageBaselineRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LanguageBaseline) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.summary)) {
                return ["summary \(item.summary) is too long"]
            }
            return []
        }
    }

    final class LanguageBaselineNameLengthRule: LanguageBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LanguageBaseline) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a language baseline.
    final class LanguageBaselineValidator {
        var rules: [any LanguageBaselineRule]

        init(rules: [any LanguageBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: LanguageBaseline) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LanguageBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LanguageBaseline]) -> [String: [String]] {
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

    static func defaultLanguageBaselineValidator() -> LanguageBaselineValidator {
        return LanguageBaselineValidator(
            rules: [
                LanguageBaselineRequiredNameRule(message: "language baseline needs an entry"),
                LanguageBaselineCodePrefixRule(prefix: "ACM"),
                LanguageBaselineSummaryLengthRule(maxLength: 64),
                LanguageBaselinePatientRefLengthRule(maxLength: 80),
                LanguageBaselineAllowedSummaryRule(allowed: ["default"]),
                LanguageBaselineNameLengthRule(maxLength: 86400),
            ]
        )
    }
}
