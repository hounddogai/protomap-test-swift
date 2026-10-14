import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a regional care protocol estimate must pass. Check returns its problems, or none.
    protocol RegionalCareProtocolEstimateRule {
        func check(_ item: RegionalCareProtocolEstimate) -> [String]
    }

    final class RegionalCareProtocolEstimateRequiredCodeRule: RegionalCareProtocolEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalCareProtocolEstimate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalCareProtocolEstimateUnitLengthRule: RegionalCareProtocolEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalCareProtocolEstimate) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalCareProtocolEstimateLabelLengthRule: RegionalCareProtocolEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalCareProtocolEstimate) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalCareProtocolEstimateCodePrefixRule: RegionalCareProtocolEstimateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalCareProtocolEstimate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional care protocol estimate.
    final class RegionalCareProtocolEstimateValidator {
        var rules: [any RegionalCareProtocolEstimateRule]

        init(rules: [any RegionalCareProtocolEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalCareProtocolEstimate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalCareProtocolEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalCareProtocolEstimate]) -> [String: [String]] {
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

    static func defaultRegionalCareProtocolEstimateValidator() -> RegionalCareProtocolEstimateValidator {
        return RegionalCareProtocolEstimateValidator(
            rules: [
                RegionalCareProtocolEstimateRequiredCodeRule(
                    message: "regional care protocol estimate needs this field"
                ),
                RegionalCareProtocolEstimateUnitLengthRule(maxLength: 255),
                RegionalCareProtocolEstimateLabelLengthRule(maxLength: 1000),
                RegionalCareProtocolEstimateCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
