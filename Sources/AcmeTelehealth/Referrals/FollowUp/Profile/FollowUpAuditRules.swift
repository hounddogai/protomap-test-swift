import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a follow up audit must pass. Check returns its problems, or none.
    protocol FollowUpAuditRule {
        func check(_ item: FollowUpAudit) -> [String]
    }

    final class FollowUpAuditAllowedLabelRule: FollowUpAuditRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FollowUpAudit) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is too long"]
            }
            return []
        }
    }

    final class FollowUpAuditSpecialtyLengthRule: FollowUpAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpAudit) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FollowUpAuditRequiredCategoryRule: FollowUpAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FollowUpAudit) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FollowUpAuditLabelLengthRule: FollowUpAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpAudit) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a follow up audit.
    final class FollowUpAuditValidator {
        var rules: [any FollowUpAuditRule]

        init(rules: [any FollowUpAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: FollowUpAudit) -> [String] {
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

        func requireValid(_ item: FollowUpAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FollowUpAudit]) -> [String: [String]] {
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

    static func defaultFollowUpAuditValidator() -> FollowUpAuditValidator {
        return FollowUpAuditValidator(
            rules: [
                FollowUpAuditAllowedLabelRule(allowed: ["lenient", "pending", "legacy"]),
                FollowUpAuditSpecialtyLengthRule(maxLength: 80),
                FollowUpAuditRequiredCategoryRule(message: "follow up audit needs this field"),
                FollowUpAuditLabelLengthRule(maxLength: 64),
            ]
        )
    }
}
