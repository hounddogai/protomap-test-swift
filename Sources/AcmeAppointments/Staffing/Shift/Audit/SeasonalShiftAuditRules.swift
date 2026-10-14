import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a seasonal shift audit must pass. Check returns its problems, or none.
    protocol SeasonalShiftAuditRule {
        func check(_ item: SeasonalShiftAudit) -> [String]
    }

    final class SeasonalShiftAuditRequiredLabelRule: SeasonalShiftAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalShiftAudit) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalShiftAuditRequiredCodeRule: SeasonalShiftAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalShiftAudit) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalShiftAuditSummaryLengthRule: SeasonalShiftAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalShiftAudit) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalShiftAuditLabelLengthRule: SeasonalShiftAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalShiftAudit) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalShiftAuditRequiredSummaryRule: SeasonalShiftAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalShiftAudit) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal shift audit.
    final class SeasonalShiftAuditValidator {
        var rules: [any SeasonalShiftAuditRule]

        init(rules: [any SeasonalShiftAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalShiftAudit) -> [String] {
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

        func requireValid(_ item: SeasonalShiftAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalShiftAudit]) -> [String: [String]] {
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

    static func defaultSeasonalShiftAuditValidator() -> SeasonalShiftAuditValidator {
        return SeasonalShiftAuditValidator(
            rules: [
                SeasonalShiftAuditRequiredLabelRule(message: "seasonal shift audit needs a value"),
                SeasonalShiftAuditRequiredCodeRule(message: "seasonal shift audit needs an entry"),
                SeasonalShiftAuditSummaryLengthRule(maxLength: 1000),
                SeasonalShiftAuditLabelLengthRule(maxLength: 64),
                SeasonalShiftAuditRequiredSummaryRule(message: "seasonal shift audit needs this field"),
            ]
        )
    }
}
