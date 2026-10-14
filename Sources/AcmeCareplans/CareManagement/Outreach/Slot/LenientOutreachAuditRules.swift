import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a lenient outreach audit must pass. Check returns its problems, or none.
    protocol LenientOutreachAuditRule {
        func check(_ item: LenientOutreachAudit) -> [String]
    }

    final class LenientOutreachAuditEncounterIDLengthRule: LenientOutreachAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientOutreachAudit) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientOutreachAuditRequiredWardRule: LenientOutreachAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientOutreachAudit) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientOutreachAuditRequiredTitleRule: LenientOutreachAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientOutreachAudit) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientOutreachAuditTitleLengthRule: LenientOutreachAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientOutreachAudit) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientOutreachAuditCodeLengthRule: LenientOutreachAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientOutreachAudit) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient outreach audit.
    final class LenientOutreachAuditValidator {
        var rules: [any LenientOutreachAuditRule]

        init(rules: [any LenientOutreachAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientOutreachAudit) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientOutreachAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientOutreachAudit]) -> [String: [String]] {
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

    static func defaultLenientOutreachAuditValidator() -> LenientOutreachAuditValidator {
        return LenientOutreachAuditValidator(
            rules: [
                LenientOutreachAuditEncounterIDLengthRule(maxLength: 1000),
                LenientOutreachAuditRequiredWardRule(message: "lenient outreach audit needs an entry"),
                LenientOutreachAuditRequiredTitleRule(message: "lenient outreach audit needs a value"),
                LenientOutreachAuditTitleLengthRule(maxLength: 16),
                LenientOutreachAuditCodeLengthRule(maxLength: 255),
            ]
        )
    }
}
