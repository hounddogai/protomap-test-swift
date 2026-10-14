import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a skill mix audit must pass. Check returns its problems, or none.
    protocol SkillMixAuditRule {
        func check(_ item: SkillMixAudit) -> [String]
    }

    final class SkillMixAuditCopayRangeRule: SkillMixAuditRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SkillMixAudit) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SkillMixAuditRequiredTitleRule: SkillMixAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SkillMixAudit) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SkillMixAuditApprovedGuardRule: SkillMixAuditRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: SkillMixAudit) -> [String] {
            if item.approved && (item.score > limit) {
                return ["score \(item.score) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class SkillMixAuditCodePrefixRule: SkillMixAuditRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SkillMixAudit) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SkillMixAuditReviewerLengthRule: SkillMixAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SkillMixAudit) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SkillMixAuditExpiresAtRangeRule: SkillMixAuditRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SkillMixAudit) -> [String] {
            let value = item.expiresAt
            var problems: [String] = []
            if value < min {
                problems.append("expires at \(value) is below \(min)")
            }
            if value > max {
                problems.append("expires at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a skill mix audit.
    final class SkillMixAuditValidator {
        var rules: [any SkillMixAuditRule]

        init(rules: [any SkillMixAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: SkillMixAudit) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SkillMixAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SkillMixAudit]) -> [String: [String]] {
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

    static func defaultSkillMixAuditValidator() -> SkillMixAuditValidator {
        return SkillMixAuditValidator(
            rules: [
                SkillMixAuditCopayRangeRule(min: 1.4, max: 869.4),
                SkillMixAuditRequiredTitleRule(message: "skill mix audit needs an entry"),
                SkillMixAuditApprovedGuardRule(limit: 5.1),
                SkillMixAuditCodePrefixRule(prefix: "X"),
                SkillMixAuditReviewerLengthRule(maxLength: 16),
                SkillMixAuditExpiresAtRangeRule(min: 16, max: 120),
            ]
        )
    }
}
