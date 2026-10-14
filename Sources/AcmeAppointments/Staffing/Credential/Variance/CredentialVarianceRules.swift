import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a credential variance must pass. Check returns its problems, or none.
    protocol CredentialVarianceRule {
        func check(_ item: CredentialVariance) -> [String]
    }

    final class CredentialVarianceBedLengthRule: CredentialVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialVariance) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CredentialVarianceRequiredLabelRule: CredentialVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialVariance) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CredentialVarianceRequiredBedRule: CredentialVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialVariance) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a credential variance.
    final class CredentialVarianceValidator {
        var rules: [any CredentialVarianceRule]

        init(rules: [any CredentialVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: CredentialVariance) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CredentialVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CredentialVariance]) -> [String: [String]] {
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

    static func defaultCredentialVarianceValidator() -> CredentialVarianceValidator {
        return CredentialVarianceValidator(
            rules: [
                CredentialVarianceBedLengthRule(maxLength: 1000),
                CredentialVarianceRequiredLabelRule(message: "credential variance needs a value"),
                CredentialVarianceRequiredBedRule(message: "credential variance needs a value"),
            ]
        )
    }
}
