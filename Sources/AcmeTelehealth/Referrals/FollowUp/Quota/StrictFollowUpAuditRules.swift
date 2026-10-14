import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a strict follow up audit must pass. Check returns its problems, or none.
    protocol StrictFollowUpAuditRule {
        func check(_ item: StrictFollowUpAudit) -> [String]
    }

    final class StrictFollowUpAuditRequiredCodeRule: StrictFollowUpAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictFollowUpAudit) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictFollowUpAuditMaximumRangeRule: StrictFollowUpAuditRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictFollowUpAudit) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictFollowUpAuditRequiredTitleRule: StrictFollowUpAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictFollowUpAudit) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictFollowUpAuditMarginRangeRule: StrictFollowUpAuditRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictFollowUpAudit) -> [String] {
            let value = item.margin
            var problems: [String] = []
            if value < min {
                problems.append("margin \(value) is below \(min)")
            }
            if value > max {
                problems.append("margin \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StrictFollowUpAuditNameLengthRule: StrictFollowUpAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictFollowUpAudit) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict follow up audit.
    final class StrictFollowUpAuditValidator {
        var rules: [any StrictFollowUpAuditRule]

        init(rules: [any StrictFollowUpAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictFollowUpAudit) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictFollowUpAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictFollowUpAudit]) -> [String: [String]] {
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

    static func defaultStrictFollowUpAuditValidator() -> StrictFollowUpAuditValidator {
        return StrictFollowUpAuditValidator(
            rules: [
                StrictFollowUpAuditRequiredCodeRule(message: "strict follow up audit needs this field"),
                StrictFollowUpAuditMaximumRangeRule(min: 0.9, max: 643.2),
                StrictFollowUpAuditRequiredTitleRule(message: "strict follow up audit needs a value"),
                StrictFollowUpAuditMarginRangeRule(min: 4.5, max: 4000.3),
                StrictFollowUpAuditNameLengthRule(maxLength: 80),
            ]
        )
    }
}
