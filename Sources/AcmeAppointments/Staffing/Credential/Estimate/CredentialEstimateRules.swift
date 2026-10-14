import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a credential estimate must pass. Check returns its problems, or none.
    protocol CredentialEstimateRule {
        func check(_ item: CredentialEstimate) -> [String]
    }

    final class CredentialEstimateRequiredLabelRule: CredentialEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialEstimate) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CredentialEstimateCodeLengthRule: CredentialEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialEstimate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CredentialEstimateSummaryLengthRule: CredentialEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialEstimate) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a credential estimate.
    final class CredentialEstimateValidator {
        var rules: [any CredentialEstimateRule]

        init(rules: [any CredentialEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: CredentialEstimate) -> [String] {
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

        func requireValid(_ item: CredentialEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CredentialEstimate]) -> [String: [String]] {
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

    static func defaultCredentialEstimateValidator() -> CredentialEstimateValidator {
        return CredentialEstimateValidator(
            rules: [
                CredentialEstimateRequiredLabelRule(message: "credential estimate needs this field"),
                CredentialEstimateCodeLengthRule(maxLength: 32),
                CredentialEstimateSummaryLengthRule(maxLength: 1000),
            ]
        )
    }
}
