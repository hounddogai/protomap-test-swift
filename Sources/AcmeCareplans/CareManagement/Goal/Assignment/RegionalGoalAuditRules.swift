import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a regional goal audit must pass. Check returns its problems, or none.
    protocol RegionalGoalAuditRule {
        func check(_ item: RegionalGoalAudit) -> [String]
    }

    final class RegionalGoalAuditCodeLengthRule: RegionalGoalAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalGoalAudit) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalGoalAuditRequiredCodeRule: RegionalGoalAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalGoalAudit) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalGoalAuditEndsAtRangeRule: RegionalGoalAuditRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalGoalAudit) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalGoalAuditAllowedLabelRule: RegionalGoalAuditRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalGoalAudit) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is blocked"]
            }
            return []
        }
    }

    /// Runs every rule of a regional goal audit.
    final class RegionalGoalAuditValidator {
        var rules: [any RegionalGoalAuditRule]

        init(rules: [any RegionalGoalAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalGoalAudit) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalGoalAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalGoalAudit]) -> [String: [String]] {
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

    static func defaultRegionalGoalAuditValidator() -> RegionalGoalAuditValidator {
        return RegionalGoalAuditValidator(
            rules: [
                RegionalGoalAuditCodeLengthRule(maxLength: 1000),
                RegionalGoalAuditRequiredCodeRule(message: "regional goal audit needs an entry"),
                RegionalGoalAuditEndsAtRangeRule(min: 32, max: 86400),
                RegionalGoalAuditAllowedLabelRule(allowed: ["tiered", "seasonal", "tiered"]),
            ]
        )
    }
}
