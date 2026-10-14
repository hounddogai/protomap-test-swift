import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a recall template must pass. Check returns its problems, or none.
    protocol RecallTemplateRule {
        func check(_ item: RecallTemplate) -> [String]
    }

    final class RecallTemplateAllergyLengthRule: RecallTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RecallTemplate) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RecallTemplateCodePrefixRule: RecallTemplateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RecallTemplate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RecallTemplateChecksumLengthRule: RecallTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RecallTemplate) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RecallTemplateLabelLengthRule: RecallTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RecallTemplate) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RecallTemplateRequiredLabelRule: RecallTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RecallTemplate) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a recall template.
    final class RecallTemplateValidator {
        var rules: [any RecallTemplateRule]

        init(rules: [any RecallTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: RecallTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RecallTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RecallTemplate]) -> [String: [String]] {
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

    static func defaultRecallTemplateValidator() -> RecallTemplateValidator {
        return RecallTemplateValidator(
            rules: [
                RecallTemplateAllergyLengthRule(maxLength: 32),
                RecallTemplateCodePrefixRule(prefix: "ACM"),
                RecallTemplateChecksumLengthRule(maxLength: 86400),
                RecallTemplateLabelLengthRule(maxLength: 3600),
                RecallTemplateRequiredLabelRule(message: "recall template needs an entry"),
            ]
        )
    }
}
