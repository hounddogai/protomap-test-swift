import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a scheduled modality audit must pass. Check returns its problems, or none.
    protocol ScheduledModalityAuditRule {
        func check(_ item: ScheduledModalityAudit) -> [String]
    }

    final class ScheduledModalityAuditDiagnosisCodeLengthRule: ScheduledModalityAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledModalityAudit) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledModalityAuditCodeLengthRule: ScheduledModalityAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledModalityAudit) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledModalityAuditRequiredDiagnosisCodeRule: ScheduledModalityAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledModalityAudit) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledModalityAuditRatioRangeRule: ScheduledModalityAuditRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledModalityAudit) -> [String] {
            let value = item.ratio
            var problems: [String] = []
            if value < min {
                problems.append("ratio \(value) is below \(min)")
            }
            if value > max {
                problems.append("ratio \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a scheduled modality audit.
    final class ScheduledModalityAuditValidator {
        var rules: [any ScheduledModalityAuditRule]

        init(rules: [any ScheduledModalityAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledModalityAudit) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledModalityAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledModalityAudit]) -> [String: [String]] {
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

    static func defaultScheduledModalityAuditValidator() -> ScheduledModalityAuditValidator {
        return ScheduledModalityAuditValidator(
            rules: [
                ScheduledModalityAuditDiagnosisCodeLengthRule(maxLength: 86400),
                ScheduledModalityAuditCodeLengthRule(maxLength: 16),
                ScheduledModalityAuditRequiredDiagnosisCodeRule(message: "scheduled modality audit needs an entry"),
                ScheduledModalityAuditRatioRangeRule(min: 6.7, max: 2180.9),
            ]
        )
    }
}
