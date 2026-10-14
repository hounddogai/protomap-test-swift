import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a assessment score must pass. Check returns its problems, or none.
    protocol AssessmentScoreRule {
        func check(_ item: AssessmentScore) -> [String]
    }

    final class AssessmentScoreReviewerLengthRule: AssessmentScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AssessmentScore) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AssessmentScoreRequiredCodeRule: AssessmentScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AssessmentScore) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AssessmentScoreRetriesRangeRule: AssessmentScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AssessmentScore) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a assessment score.
    final class AssessmentScoreValidator {
        var rules: [any AssessmentScoreRule]

        init(rules: [any AssessmentScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: AssessmentScore) -> [String] {
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

        func requireValid(_ item: AssessmentScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AssessmentScore]) -> [String: [String]] {
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

    static func defaultAssessmentScoreValidator() -> AssessmentScoreValidator {
        return AssessmentScoreValidator(
            rules: [
                AssessmentScoreReviewerLengthRule(maxLength: 80),
                AssessmentScoreRequiredCodeRule(message: "assessment score needs a value"),
                AssessmentScoreRetriesRangeRule(min: 1000, max: 3600),
            ]
        )
    }
}
