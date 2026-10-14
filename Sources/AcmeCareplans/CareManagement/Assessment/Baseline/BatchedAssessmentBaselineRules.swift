import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a batched assessment baseline must pass. Check returns its problems, or none.
    protocol BatchedAssessmentBaselineRule {
        func check(_ item: BatchedAssessmentBaseline) -> [String]
    }

    final class BatchedAssessmentBaselineRequiredContactEmailRule: BatchedAssessmentBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedAssessmentBaseline) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedAssessmentBaselineCapacityRangeRule: BatchedAssessmentBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedAssessmentBaseline) -> [String] {
            let value = item.capacity
            var problems: [String] = []
            if value < min {
                problems.append("capacity \(value) is below \(min)")
            }
            if value > max {
                problems.append("capacity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BatchedAssessmentBaselineRevisionRangeRule: BatchedAssessmentBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedAssessmentBaseline) -> [String] {
            let value = item.revision
            var problems: [String] = []
            if value < min {
                problems.append("revision \(value) is below \(min)")
            }
            if value > max {
                problems.append("revision \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a batched assessment baseline.
    final class BatchedAssessmentBaselineValidator {
        var rules: [any BatchedAssessmentBaselineRule]

        init(rules: [any BatchedAssessmentBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedAssessmentBaseline) -> [String] {
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

        func requireValid(_ item: BatchedAssessmentBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedAssessmentBaseline]) -> [String: [String]] {
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

    static func defaultBatchedAssessmentBaselineValidator() -> BatchedAssessmentBaselineValidator {
        return BatchedAssessmentBaselineValidator(
            rules: [
                BatchedAssessmentBaselineRequiredContactEmailRule(
                    message: "batched assessment baseline needs this field"
                ),
                BatchedAssessmentBaselineCapacityRangeRule(min: 64, max: 120),
                BatchedAssessmentBaselineRevisionRangeRule(min: 16, max: 3600),
            ]
        )
    }
}
