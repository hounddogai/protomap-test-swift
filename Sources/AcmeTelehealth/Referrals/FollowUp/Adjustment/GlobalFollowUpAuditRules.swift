import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a global follow up audit must pass. Check returns its problems, or none.
    protocol GlobalFollowUpAuditRule {
        func check(_ item: GlobalFollowUpAudit) -> [String]
    }

    final class GlobalFollowUpAuditRequiredUnitRule: GlobalFollowUpAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalFollowUpAudit) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalFollowUpAuditAllowedLabelRule: GlobalFollowUpAuditRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalFollowUpAudit) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is unknown"]
            }
            return []
        }
    }

    final class GlobalFollowUpAuditMinimumRangeRule: GlobalFollowUpAuditRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalFollowUpAudit) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a global follow up audit.
    final class GlobalFollowUpAuditValidator {
        var rules: [any GlobalFollowUpAuditRule]

        init(rules: [any GlobalFollowUpAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalFollowUpAudit) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalFollowUpAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalFollowUpAudit]) -> [String: [String]] {
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

    static func defaultGlobalFollowUpAuditValidator() -> GlobalFollowUpAuditValidator {
        return GlobalFollowUpAuditValidator(
            rules: [
                GlobalFollowUpAuditRequiredUnitRule(message: "global follow up audit needs a value"),
                GlobalFollowUpAuditAllowedLabelRule(allowed: ["scheduled"]),
                GlobalFollowUpAuditMinimumRangeRule(min: 9.1, max: 2797.7),
            ]
        )
    }
}
