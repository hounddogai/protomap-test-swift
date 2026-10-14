import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a rolling discharge plan score must pass. Check returns its problems, or none.
    protocol RollingDischargePlanScoreRule {
        func check(_ item: RollingDischargePlanScore) -> [String]
    }

    final class RollingDischargePlanScoreRequiredTitleRule: RollingDischargePlanScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingDischargePlanScore) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingDischargePlanScoreRequiredCodeRule: RollingDischargePlanScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingDischargePlanScore) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingDischargePlanScoreRequiredBedRule: RollingDischargePlanScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingDischargePlanScore) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rolling discharge plan score.
    final class RollingDischargePlanScoreValidator {
        var rules: [any RollingDischargePlanScoreRule]

        init(rules: [any RollingDischargePlanScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingDischargePlanScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingDischargePlanScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingDischargePlanScore]) -> [String: [String]] {
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

    static func defaultRollingDischargePlanScoreValidator() -> RollingDischargePlanScoreValidator {
        return RollingDischargePlanScoreValidator(
            rules: [
                RollingDischargePlanScoreRequiredTitleRule(message: "rolling discharge plan score needs a value"),
                RollingDischargePlanScoreRequiredCodeRule(message: "rolling discharge plan score needs this field"),
                RollingDischargePlanScoreRequiredBedRule(message: "rolling discharge plan score needs this field"),
            ]
        )
    }
}
