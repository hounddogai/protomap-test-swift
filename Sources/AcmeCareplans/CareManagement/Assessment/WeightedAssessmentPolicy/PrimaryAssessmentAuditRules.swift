import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a primary assessment audit must pass. Check returns its problems, or none.
    protocol PrimaryAssessmentAuditRule {
        func check(_ item: PrimaryAssessmentAudit) -> [String]
    }

    final class PrimaryAssessmentAuditNameLengthRule: PrimaryAssessmentAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryAssessmentAudit) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryAssessmentAuditMaximumRangeRule: PrimaryAssessmentAuditRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryAssessmentAudit) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PrimaryAssessmentAuditRequiredNameRule: PrimaryAssessmentAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryAssessmentAudit) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a primary assessment audit.
    final class PrimaryAssessmentAuditValidator {
        var rules: [any PrimaryAssessmentAuditRule]

        init(rules: [any PrimaryAssessmentAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryAssessmentAudit) -> [String] {
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

        func requireValid(_ item: PrimaryAssessmentAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryAssessmentAudit]) -> [String: [String]] {
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

    static func defaultPrimaryAssessmentAuditValidator() -> PrimaryAssessmentAuditValidator {
        return PrimaryAssessmentAuditValidator(
            rules: [
                PrimaryAssessmentAuditNameLengthRule(maxLength: 120),
                PrimaryAssessmentAuditMaximumRangeRule(min: 0.7, max: 4723.1),
                PrimaryAssessmentAuditRequiredNameRule(message: "primary assessment audit needs this field"),
            ]
        )
    }
}
