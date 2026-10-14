import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a legacy follow up audit must pass. Check returns its problems, or none.
    protocol LegacyFollowUpAuditRule {
        func check(_ item: LegacyFollowUpAudit) -> [String]
    }

    final class LegacyFollowUpAuditCodeLengthRule: LegacyFollowUpAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyFollowUpAudit) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyFollowUpAuditRequiredTimezoneRule: LegacyFollowUpAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyFollowUpAudit) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyFollowUpAuditRequiredLabelRule: LegacyFollowUpAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyFollowUpAudit) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a legacy follow up audit.
    final class LegacyFollowUpAuditValidator {
        var rules: [any LegacyFollowUpAuditRule]

        init(rules: [any LegacyFollowUpAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyFollowUpAudit) -> [String] {
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

        func requireValid(_ item: LegacyFollowUpAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyFollowUpAudit]) -> [String: [String]] {
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

    static func defaultLegacyFollowUpAuditValidator() -> LegacyFollowUpAuditValidator {
        return LegacyFollowUpAuditValidator(
            rules: [
                LegacyFollowUpAuditCodeLengthRule(maxLength: 3600),
                LegacyFollowUpAuditRequiredTimezoneRule(message: "legacy follow up audit needs a value"),
                LegacyFollowUpAuditRequiredLabelRule(message: "legacy follow up audit needs a value"),
            ]
        )
    }
}
