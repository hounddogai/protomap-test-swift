import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a batched assessment estimate must pass. Check returns its problems, or none.
    protocol BatchedAssessmentEstimateRule {
        func check(_ item: BatchedAssessmentEstimate) -> [String]
    }

    final class BatchedAssessmentEstimateRequiredProcedureCodeRule: BatchedAssessmentEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedAssessmentEstimate) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedAssessmentEstimateCodeLengthRule: BatchedAssessmentEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedAssessmentEstimate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedAssessmentEstimateLabelLengthRule: BatchedAssessmentEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedAssessmentEstimate) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched assessment estimate.
    final class BatchedAssessmentEstimateValidator {
        var rules: [any BatchedAssessmentEstimateRule]

        init(rules: [any BatchedAssessmentEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedAssessmentEstimate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedAssessmentEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedAssessmentEstimate]) -> [String: [String]] {
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

    static func defaultBatchedAssessmentEstimateValidator() -> BatchedAssessmentEstimateValidator {
        return BatchedAssessmentEstimateValidator(
            rules: [
                BatchedAssessmentEstimateRequiredProcedureCodeRule(
                    message: "batched assessment estimate needs an entry"
                ),
                BatchedAssessmentEstimateCodeLengthRule(maxLength: 80),
                BatchedAssessmentEstimateLabelLengthRule(maxLength: 64),
            ]
        )
    }
}
