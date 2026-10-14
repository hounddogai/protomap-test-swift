import AcmePlatform
import Foundation

extension Consent {
    /// A rule a adaptive consent form exception must pass. Check returns its problems, or none.
    protocol AdaptiveConsentFormExceptionRule {
        func check(_ item: AdaptiveConsentFormException) -> [String]
    }

    final class AdaptiveConsentFormExceptionCodePrefixRule: AdaptiveConsentFormExceptionRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveConsentFormException) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveConsentFormExceptionRequiredCodeRule: AdaptiveConsentFormExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveConsentFormException) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveConsentFormExceptionPayerLengthRule: AdaptiveConsentFormExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveConsentFormException) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveConsentFormExceptionRequiredCategoryRule: AdaptiveConsentFormExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveConsentFormException) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveConsentFormExceptionTitleLengthRule: AdaptiveConsentFormExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveConsentFormException) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive consent form exception.
    final class AdaptiveConsentFormExceptionValidator {
        var rules: [any AdaptiveConsentFormExceptionRule]

        init(rules: [any AdaptiveConsentFormExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveConsentFormException) -> [String] {
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

        func requireValid(_ item: AdaptiveConsentFormException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveConsentFormException]) -> [String: [String]] {
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

    static func defaultAdaptiveConsentFormExceptionValidator() -> AdaptiveConsentFormExceptionValidator {
        return AdaptiveConsentFormExceptionValidator(
            rules: [
                AdaptiveConsentFormExceptionCodePrefixRule(prefix: "REF"),
                AdaptiveConsentFormExceptionRequiredCodeRule(
                    message: "adaptive consent form exception needs this field"
                ),
                AdaptiveConsentFormExceptionPayerLengthRule(maxLength: 255),
                AdaptiveConsentFormExceptionRequiredCategoryRule(
                    message: "adaptive consent form exception needs an entry"
                ),
                AdaptiveConsentFormExceptionTitleLengthRule(maxLength: 255),
            ]
        )
    }
}
