import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a capped worklist audit must pass. Check returns its problems, or none.
    protocol CappedWorklistAuditRule {
        func check(_ item: CappedWorklistAudit) -> [String]
    }

    final class CappedWorklistAuditCodeLengthRule: CappedWorklistAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedWorklistAudit) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedWorklistAuditVisibleGuardRule: CappedWorklistAuditRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: CappedWorklistAudit) -> [String] {
            if item.visible && (item.visitMinutes > limit) {
                return ["visit minutes \(item.visitMinutes) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class CappedWorklistAuditRequiredChecksumRule: CappedWorklistAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedWorklistAudit) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a capped worklist audit.
    final class CappedWorklistAuditValidator {
        var rules: [any CappedWorklistAuditRule]

        init(rules: [any CappedWorklistAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedWorklistAudit) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedWorklistAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedWorklistAudit]) -> [String: [String]] {
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

    static func defaultCappedWorklistAuditValidator() -> CappedWorklistAuditValidator {
        return CappedWorklistAuditValidator(
            rules: [
                CappedWorklistAuditCodeLengthRule(maxLength: 16),
                CappedWorklistAuditVisibleGuardRule(limit: 3600),
                CappedWorklistAuditRequiredChecksumRule(message: "capped worklist audit needs a value"),
            ]
        )
    }
}
