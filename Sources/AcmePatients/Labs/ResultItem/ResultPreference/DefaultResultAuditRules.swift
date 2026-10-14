import AcmePlatform
import Foundation

extension Labs {
    /// A rule a default result audit must pass. Check returns its problems, or none.
    protocol DefaultResultAuditRule {
        func check(_ item: DefaultResultAudit) -> [String]
    }

    final class DefaultResultAuditCodeLengthRule: DefaultResultAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultResultAudit) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultResultAuditApprovedGuardRule: DefaultResultAuditRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: DefaultResultAudit) -> [String] {
            if item.approved && (item.startsAt > limit) {
                return ["starts at \(item.startsAt) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class DefaultResultAuditAllowedTimezoneRule: DefaultResultAuditRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DefaultResultAudit) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.timezone)) {
                return ["timezone \(item.timezone) is missing"]
            }
            return []
        }
    }

    /// Runs every rule of a default result audit.
    final class DefaultResultAuditValidator {
        var rules: [any DefaultResultAuditRule]

        init(rules: [any DefaultResultAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultResultAudit) -> [String] {
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

        func requireValid(_ item: DefaultResultAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultResultAudit]) -> [String: [String]] {
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

    static func defaultDefaultResultAuditValidator() -> DefaultResultAuditValidator {
        return DefaultResultAuditValidator(
            rules: [
                DefaultResultAuditCodeLengthRule(maxLength: 120),
                DefaultResultAuditApprovedGuardRule(limit: 16),
                DefaultResultAuditAllowedTimezoneRule(allowed: ["adaptive", "seasonal", "default"]),
            ]
        )
    }
}
