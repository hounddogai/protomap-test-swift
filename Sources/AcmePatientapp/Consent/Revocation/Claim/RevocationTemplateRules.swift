import AcmePlatform
import Foundation

extension Consent {
    /// A rule a revocation template must pass. Check returns its problems, or none.
    protocol RevocationTemplateRule {
        func check(_ item: RevocationTemplate) -> [String]
    }

    final class RevocationTemplateCodeLengthRule: RevocationTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RevocationTemplate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RevocationTemplateRequiredCodeRule: RevocationTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RevocationTemplate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RevocationTemplateCountryLengthRule: RevocationTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RevocationTemplate) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RevocationTemplateRequiredProcedureCodeRule: RevocationTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RevocationTemplate) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a revocation template.
    final class RevocationTemplateValidator {
        var rules: [any RevocationTemplateRule]

        init(rules: [any RevocationTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: RevocationTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RevocationTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RevocationTemplate]) -> [String: [String]] {
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

    static func defaultRevocationTemplateValidator() -> RevocationTemplateValidator {
        return RevocationTemplateValidator(
            rules: [
                RevocationTemplateCodeLengthRule(maxLength: 80),
                RevocationTemplateRequiredCodeRule(message: "revocation template needs this field"),
                RevocationTemplateCountryLengthRule(maxLength: 1000),
                RevocationTemplateRequiredProcedureCodeRule(message: "revocation template needs an entry"),
            ]
        )
    }
}
