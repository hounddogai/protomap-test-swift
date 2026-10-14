import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a regional assessment estimate must pass. Check returns its problems, or none.
    protocol RegionalAssessmentEstimateRule {
        func check(_ item: RegionalAssessmentEstimate) -> [String]
    }

    final class RegionalAssessmentEstimateExternalRefLengthRule: RegionalAssessmentEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalAssessmentEstimate) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalAssessmentEstimateCodePrefixRule: RegionalAssessmentEstimateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalAssessmentEstimate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RegionalAssessmentEstimateAcuityRangeRule: RegionalAssessmentEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalAssessmentEstimate) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalAssessmentEstimateRequiredExternalRefRule: RegionalAssessmentEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalAssessmentEstimate) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional assessment estimate.
    final class RegionalAssessmentEstimateValidator {
        var rules: [any RegionalAssessmentEstimateRule]

        init(rules: [any RegionalAssessmentEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalAssessmentEstimate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalAssessmentEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalAssessmentEstimate]) -> [String: [String]] {
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

    static func defaultRegionalAssessmentEstimateValidator() -> RegionalAssessmentEstimateValidator {
        return RegionalAssessmentEstimateValidator(
            rules: [
                RegionalAssessmentEstimateExternalRefLengthRule(maxLength: 80),
                RegionalAssessmentEstimateCodePrefixRule(prefix: "X"),
                RegionalAssessmentEstimateAcuityRangeRule(min: 80, max: 3600),
                RegionalAssessmentEstimateRequiredExternalRefRule(
                    message: "regional assessment estimate needs this field"
                ),
            ]
        )
    }
}
