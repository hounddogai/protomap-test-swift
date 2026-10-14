import AcmePlatform
import Foundation

extension Consent {
    /// A rule a revocation milestone must pass. Check returns its problems, or none.
    protocol RevocationMilestoneRule {
        func check(_ item: RevocationMilestone) -> [String]
    }

    final class RevocationMilestoneActiveGuardRule: RevocationMilestoneRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: RevocationMilestone) -> [String] {
            if item.active && (item.margin > limit) {
                return ["margin \(item.margin) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class RevocationMilestoneCodePrefixRule: RevocationMilestoneRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RevocationMilestone) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RevocationMilestoneMarginRangeRule: RevocationMilestoneRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RevocationMilestone) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a revocation milestone.
    final class RevocationMilestoneValidator {
        var rules: [any RevocationMilestoneRule]

        init(rules: [any RevocationMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: RevocationMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RevocationMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RevocationMilestone]) -> [String: [String]] {
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

    static func defaultRevocationMilestoneValidator() -> RevocationMilestoneValidator {
        return RevocationMilestoneValidator(
            rules: [
                RevocationMilestoneActiveGuardRule(limit: 3.9),
                RevocationMilestoneCodePrefixRule(prefix: "REF"),
                RevocationMilestoneMarginRangeRule(min: 9.8, max: 2515.5),
            ]
        )
    }
}
