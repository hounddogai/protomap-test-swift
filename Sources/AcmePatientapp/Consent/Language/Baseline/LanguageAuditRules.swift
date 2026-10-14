import AcmePlatform
import Foundation

extension Consent {
    /// A rule a language audit must pass. Check returns its problems, or none.
    protocol LanguageAuditRule {
        func check(_ item: LanguageAudit) -> [String]
    }

    final class LanguageAuditNameLengthRule: LanguageAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LanguageAudit) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LanguageAuditApprovedGuardRule: LanguageAuditRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: LanguageAudit) -> [String] {
            if item.approved && (item.attempts > limit) {
                return ["attempts \(item.attempts) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class LanguageAuditAmountRangeRule: LanguageAuditRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LanguageAudit) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a language audit.
    final class LanguageAuditValidator {
        var rules: [any LanguageAuditRule]

        init(rules: [any LanguageAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: LanguageAudit) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LanguageAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LanguageAudit]) -> [String: [String]] {
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

    static func defaultLanguageAuditValidator() -> LanguageAuditValidator {
        return LanguageAuditValidator(
            rules: [
                LanguageAuditNameLengthRule(maxLength: 64),
                LanguageAuditApprovedGuardRule(limit: 80),
                LanguageAuditAmountRangeRule(min: 1.8, max: 2832.9),
            ]
        )
    }
}
