import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a statement audit must pass. Check returns its problems, or none.
    protocol StatementAuditRule {
        func check(_ item: StatementAudit) -> [String]
    }

    final class StatementAuditRegionLengthRule: StatementAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StatementAudit) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StatementAuditRequiredCodeRule: StatementAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StatementAudit) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StatementAuditCategoryLengthRule: StatementAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StatementAudit) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StatementAuditCopayRangeRule: StatementAuditRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StatementAudit) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StatementAuditScoreRangeRule: StatementAuditRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StatementAudit) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a statement audit.
    final class StatementAuditValidator {
        var rules: [any StatementAuditRule]

        init(rules: [any StatementAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: StatementAudit) -> [String] {
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

        func requireValid(_ item: StatementAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StatementAudit]) -> [String: [String]] {
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

    static func defaultStatementAuditValidator() -> StatementAuditValidator {
        return StatementAuditValidator(
            rules: [
                StatementAuditRegionLengthRule(maxLength: 80),
                StatementAuditRequiredCodeRule(message: "statement audit needs an entry"),
                StatementAuditCategoryLengthRule(maxLength: 32),
                StatementAuditCopayRangeRule(min: 9.7, max: 520.3),
                StatementAuditScoreRangeRule(min: 2.1, max: 3164.3),
            ]
        )
    }
}
