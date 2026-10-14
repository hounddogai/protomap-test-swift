import AcmePlatform
import Foundation

extension Consent {
    /// A rule a regional revocation estimate must pass. Check returns its problems, or none.
    protocol RegionalRevocationEstimateRule {
        func check(_ item: RegionalRevocationEstimate) -> [String]
    }

    final class RegionalRevocationEstimateDiagnosisCodeLengthRule: RegionalRevocationEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalRevocationEstimate) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalRevocationEstimateRequiredCodeRule: RegionalRevocationEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalRevocationEstimate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalRevocationEstimateCodePrefixRule: RegionalRevocationEstimateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalRevocationEstimate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RegionalRevocationEstimateRequiredTitleRule: RegionalRevocationEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalRevocationEstimate) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional revocation estimate.
    final class RegionalRevocationEstimateValidator {
        var rules: [any RegionalRevocationEstimateRule]

        init(rules: [any RegionalRevocationEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalRevocationEstimate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalRevocationEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalRevocationEstimate]) -> [String: [String]] {
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

    static func defaultRegionalRevocationEstimateValidator() -> RegionalRevocationEstimateValidator {
        return RegionalRevocationEstimateValidator(
            rules: [
                RegionalRevocationEstimateDiagnosisCodeLengthRule(maxLength: 120),
                RegionalRevocationEstimateRequiredCodeRule(message: "regional revocation estimate needs a value"),
                RegionalRevocationEstimateCodePrefixRule(prefix: "OPS"),
                RegionalRevocationEstimateRequiredTitleRule(message: "regional revocation estimate needs this field"),
            ]
        )
    }
}
