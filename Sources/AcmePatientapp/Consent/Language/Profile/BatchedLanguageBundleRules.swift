import AcmePlatform
import Foundation

extension Consent {
    /// A rule a batched language bundle must pass. Check returns its problems, or none.
    protocol BatchedLanguageBundleRule {
        func check(_ item: BatchedLanguageBundle) -> [String]
    }

    final class BatchedLanguageBundleCodePrefixRule: BatchedLanguageBundleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedLanguageBundle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class BatchedLanguageBundleRequiredAllergyRule: BatchedLanguageBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedLanguageBundle) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedLanguageBundleNameLengthRule: BatchedLanguageBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedLanguageBundle) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedLanguageBundleRequiredNameRule: BatchedLanguageBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedLanguageBundle) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a batched language bundle.
    final class BatchedLanguageBundleValidator {
        var rules: [any BatchedLanguageBundleRule]

        init(rules: [any BatchedLanguageBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedLanguageBundle) -> [String] {
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

        func requireValid(_ item: BatchedLanguageBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedLanguageBundle]) -> [String: [String]] {
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

    static func defaultBatchedLanguageBundleValidator() -> BatchedLanguageBundleValidator {
        return BatchedLanguageBundleValidator(
            rules: [
                BatchedLanguageBundleCodePrefixRule(prefix: "X"),
                BatchedLanguageBundleRequiredAllergyRule(message: "batched language bundle needs this field"),
                BatchedLanguageBundleNameLengthRule(maxLength: 80),
                BatchedLanguageBundleRequiredNameRule(message: "batched language bundle needs an entry"),
            ]
        )
    }
}
