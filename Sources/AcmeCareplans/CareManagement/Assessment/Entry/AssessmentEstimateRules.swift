import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a assessment estimate must pass. Check returns its problems, or none.
    protocol AssessmentEstimateRule {
        func check(_ item: AssessmentEstimate) -> [String]
    }

    final class AssessmentEstimateAllowedCodeRule: AssessmentEstimateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AssessmentEstimate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is expired"]
            }
            return []
        }
    }

    final class AssessmentEstimateProcedureCodeLengthRule: AssessmentEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AssessmentEstimate) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AssessmentEstimateRequiredProcedureCodeRule: AssessmentEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AssessmentEstimate) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AssessmentEstimateRequiredCodeRule: AssessmentEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AssessmentEstimate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AssessmentEstimateCostRangeRule: AssessmentEstimateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AssessmentEstimate) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AssessmentEstimateRequiredChannelRule: AssessmentEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AssessmentEstimate) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a assessment estimate.
    final class AssessmentEstimateValidator {
        var rules: [any AssessmentEstimateRule]

        init(rules: [any AssessmentEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: AssessmentEstimate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AssessmentEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AssessmentEstimate]) -> [String: [String]] {
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

    static func defaultAssessmentEstimateValidator() -> AssessmentEstimateValidator {
        return AssessmentEstimateValidator(
            rules: [
                AssessmentEstimateAllowedCodeRule(allowed: ["default", "global", "rolling"]),
                AssessmentEstimateProcedureCodeLengthRule(maxLength: 64),
                AssessmentEstimateRequiredProcedureCodeRule(message: "assessment estimate needs an entry"),
                AssessmentEstimateRequiredCodeRule(message: "assessment estimate needs a value"),
                AssessmentEstimateCostRangeRule(min: 8.9, max: 2493.2),
                AssessmentEstimateRequiredChannelRule(message: "assessment estimate needs a value"),
            ]
        )
    }
}
