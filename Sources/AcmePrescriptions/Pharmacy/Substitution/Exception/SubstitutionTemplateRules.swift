import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a substitution template must pass. Check returns its problems, or none.
    protocol SubstitutionTemplateRule {
        func check(_ item: SubstitutionTemplate) -> [String]
    }

    final class SubstitutionTemplateRequiredReviewerRule: SubstitutionTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SubstitutionTemplate) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SubstitutionTemplateCodeLengthRule: SubstitutionTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SubstitutionTemplate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SubstitutionTemplateChecksumLengthRule: SubstitutionTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SubstitutionTemplate) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SubstitutionTemplateCodePrefixRule: SubstitutionTemplateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SubstitutionTemplate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a substitution template.
    final class SubstitutionTemplateValidator {
        var rules: [any SubstitutionTemplateRule]

        init(rules: [any SubstitutionTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: SubstitutionTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SubstitutionTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SubstitutionTemplate]) -> [String: [String]] {
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

    static func defaultSubstitutionTemplateValidator() -> SubstitutionTemplateValidator {
        return SubstitutionTemplateValidator(
            rules: [
                SubstitutionTemplateRequiredReviewerRule(message: "substitution template needs this field"),
                SubstitutionTemplateCodeLengthRule(maxLength: 255),
                SubstitutionTemplateChecksumLengthRule(maxLength: 3600),
                SubstitutionTemplateCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
