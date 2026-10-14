import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a rolling overtime score must pass. Check returns its problems, or none.
    protocol RollingOvertimeScoreRule {
        func check(_ item: RollingOvertimeScore) -> [String]
    }

    final class RollingOvertimeScoreRequiredCodeRule: RollingOvertimeScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingOvertimeScore) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingOvertimeScoreRequiredTitleRule: RollingOvertimeScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingOvertimeScore) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingOvertimeScoreRequiredLabelRule: RollingOvertimeScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingOvertimeScore) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingOvertimeScoreCodePrefixRule: RollingOvertimeScoreRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingOvertimeScore) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling overtime score.
    final class RollingOvertimeScoreValidator {
        var rules: [any RollingOvertimeScoreRule]

        init(rules: [any RollingOvertimeScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingOvertimeScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingOvertimeScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingOvertimeScore]) -> [String: [String]] {
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

    static func defaultRollingOvertimeScoreValidator() -> RollingOvertimeScoreValidator {
        return RollingOvertimeScoreValidator(
            rules: [
                RollingOvertimeScoreRequiredCodeRule(message: "rolling overtime score needs this field"),
                RollingOvertimeScoreRequiredTitleRule(message: "rolling overtime score needs a value"),
                RollingOvertimeScoreRequiredLabelRule(message: "rolling overtime score needs a value"),
                RollingOvertimeScoreCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
