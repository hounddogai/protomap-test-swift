import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a assessment request must pass. Check returns its problems, or none.
    protocol AssessmentRequestRule {
        func check(_ item: AssessmentRequest) -> [String]
    }

    final class AssessmentRequestVersionRangeRule: AssessmentRequestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AssessmentRequest) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AssessmentRequestRequiredProcedureCodeRule: AssessmentRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AssessmentRequest) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AssessmentRequestAllowedTitleRule: AssessmentRequestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AssessmentRequest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is blocked"]
            }
            return []
        }
    }

    final class AssessmentRequestRequiredCodeRule: AssessmentRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AssessmentRequest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AssessmentRequestProcedureCodeLengthRule: AssessmentRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AssessmentRequest) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AssessmentRequestUpdatedAtRangeRule: AssessmentRequestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AssessmentRequest) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a assessment request.
    final class AssessmentRequestValidator {
        var rules: [any AssessmentRequestRule]

        init(rules: [any AssessmentRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: AssessmentRequest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AssessmentRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AssessmentRequest]) -> [String: [String]] {
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

    static func defaultAssessmentRequestValidator() -> AssessmentRequestValidator {
        return AssessmentRequestValidator(
            rules: [
                AssessmentRequestVersionRangeRule(min: 64, max: 86400),
                AssessmentRequestRequiredProcedureCodeRule(message: "assessment request needs a value"),
                AssessmentRequestAllowedTitleRule(allowed: ["manual", "scheduled", "regional"]),
                AssessmentRequestRequiredCodeRule(message: "assessment request needs an entry"),
                AssessmentRequestProcedureCodeLengthRule(maxLength: 64),
                AssessmentRequestUpdatedAtRangeRule(min: 80, max: 120),
            ]
        )
    }
}
