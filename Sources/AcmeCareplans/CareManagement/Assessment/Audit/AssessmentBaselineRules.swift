import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a assessment baseline must pass. Check returns its problems, or none.
    protocol AssessmentBaselineRule {
        func check(_ item: AssessmentBaseline) -> [String]
    }

    final class AssessmentBaselineAmountRangeRule: AssessmentBaselineRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AssessmentBaseline) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AssessmentBaselineAllowedNotesRule: AssessmentBaselineRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AssessmentBaseline) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.notes)) {
                return ["notes \(item.notes) is expired"]
            }
            return []
        }
    }

    final class AssessmentBaselineCodeLengthRule: AssessmentBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AssessmentBaseline) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a assessment baseline.
    final class AssessmentBaselineValidator {
        var rules: [any AssessmentBaselineRule]

        init(rules: [any AssessmentBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: AssessmentBaseline) -> [String] {
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

        func requireValid(_ item: AssessmentBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AssessmentBaseline]) -> [String: [String]] {
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

    static func defaultAssessmentBaselineValidator() -> AssessmentBaselineValidator {
        return AssessmentBaselineValidator(
            rules: [
                AssessmentBaselineAmountRangeRule(min: 9.1, max: 3071.9),
                AssessmentBaselineAllowedNotesRule(allowed: ["seasonal", "fallback"]),
                AssessmentBaselineCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
