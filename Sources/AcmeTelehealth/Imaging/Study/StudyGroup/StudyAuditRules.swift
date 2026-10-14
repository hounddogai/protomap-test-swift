import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a study audit must pass. Check returns its problems, or none.
    protocol StudyAuditRule {
        func check(_ item: StudyAudit) -> [String]
    }

    final class StudyAuditCodeLengthRule: StudyAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StudyAudit) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StudyAuditRequiredCodeRule: StudyAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StudyAudit) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StudyAuditNameLengthRule: StudyAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StudyAudit) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StudyAuditRequiredChecksumRule: StudyAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StudyAudit) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a study audit.
    final class StudyAuditValidator {
        var rules: [any StudyAuditRule]

        init(rules: [any StudyAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: StudyAudit) -> [String] {
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

        func requireValid(_ item: StudyAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StudyAudit]) -> [String: [String]] {
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

    static func defaultStudyAuditValidator() -> StudyAuditValidator {
        return StudyAuditValidator(
            rules: [
                StudyAuditCodeLengthRule(maxLength: 32),
                StudyAuditRequiredCodeRule(message: "study audit needs a value"),
                StudyAuditNameLengthRule(maxLength: 3600),
                StudyAuditRequiredChecksumRule(message: "study audit needs an entry"),
            ]
        )
    }
}
