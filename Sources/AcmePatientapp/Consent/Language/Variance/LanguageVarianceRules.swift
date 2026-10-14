import AcmePlatform
import Foundation

extension Consent {
    /// A rule a language variance must pass. Check returns its problems, or none.
    protocol LanguageVarianceRule {
        func check(_ item: LanguageVariance) -> [String]
    }

    final class LanguageVarianceRequiredPhoneRule: LanguageVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LanguageVariance) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LanguageVarianceRequiredCodeRule: LanguageVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LanguageVariance) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LanguageVarianceApprovedGuardRule: LanguageVarianceRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: LanguageVariance) -> [String] {
            if item.approved && (item.priority > limit) {
                return ["priority \(item.priority) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class LanguageVarianceRequiredTitleRule: LanguageVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LanguageVariance) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LanguageVarianceAllowedCodeRule: LanguageVarianceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LanguageVariance) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is out of range"]
            }
            return []
        }
    }

    final class LanguageVarianceTitleLengthRule: LanguageVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LanguageVariance) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a language variance.
    final class LanguageVarianceValidator {
        var rules: [any LanguageVarianceRule]

        init(rules: [any LanguageVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: LanguageVariance) -> [String] {
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

        func requireValid(_ item: LanguageVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LanguageVariance]) -> [String: [String]] {
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

    static func defaultLanguageVarianceValidator() -> LanguageVarianceValidator {
        return LanguageVarianceValidator(
            rules: [
                LanguageVarianceRequiredPhoneRule(message: "language variance needs an entry"),
                LanguageVarianceRequiredCodeRule(message: "language variance needs this field"),
                LanguageVarianceApprovedGuardRule(limit: 64),
                LanguageVarianceRequiredTitleRule(message: "language variance needs a value"),
                LanguageVarianceAllowedCodeRule(allowed: []),
                LanguageVarianceTitleLengthRule(maxLength: 64),
            ]
        )
    }
}
