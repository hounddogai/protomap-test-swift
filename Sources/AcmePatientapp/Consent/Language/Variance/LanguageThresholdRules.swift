import AcmePlatform
import Foundation

extension Consent {
    /// A rule a language threshold must pass. Check returns its problems, or none.
    protocol LanguageThresholdRule {
        func check(_ item: LanguageThreshold) -> [String]
    }

    final class LanguageThresholdCodeLengthRule: LanguageThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LanguageThreshold) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LanguageThresholdRequiredCountryRule: LanguageThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LanguageThreshold) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LanguageThresholdLabelLengthRule: LanguageThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LanguageThreshold) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LanguageThresholdCountryLengthRule: LanguageThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LanguageThreshold) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a language threshold.
    final class LanguageThresholdValidator {
        var rules: [any LanguageThresholdRule]

        init(rules: [any LanguageThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: LanguageThreshold) -> [String] {
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

        func requireValid(_ item: LanguageThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LanguageThreshold]) -> [String: [String]] {
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

    static func defaultLanguageThresholdValidator() -> LanguageThresholdValidator {
        return LanguageThresholdValidator(
            rules: [
                LanguageThresholdCodeLengthRule(maxLength: 64),
                LanguageThresholdRequiredCountryRule(message: "language threshold needs an entry"),
                LanguageThresholdLabelLengthRule(maxLength: 80),
                LanguageThresholdCountryLengthRule(maxLength: 1000),
            ]
        )
    }
}
