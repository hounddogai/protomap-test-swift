import AcmePlatform
import Foundation

extension Labs {
    /// A rule a result record must pass. Check returns its problems, or none.
    protocol ResultRecordRule {
        func check(_ item: ResultRecord) -> [String]
    }

    final class ResultRecordRequiredCodeRule: ResultRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ResultRecord) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ResultRecordAllowedCodeRule: ResultRecordRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ResultRecord) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is stale"]
            }
            return []
        }
    }

    final class ResultRecordRequiredLabelRule: ResultRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ResultRecord) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a result record.
    final class ResultRecordValidator {
        var rules: [any ResultRecordRule]

        init(rules: [any ResultRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: ResultRecord) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ResultRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ResultRecord]) -> [String: [String]] {
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

    static func defaultResultRecordValidator() -> ResultRecordValidator {
        return ResultRecordValidator(
            rules: [
                ResultRecordRequiredCodeRule(message: "result record needs an entry"),
                ResultRecordAllowedCodeRule(allowed: ["primary", "scheduled", "global"]),
                ResultRecordRequiredLabelRule(message: "result record needs an entry"),
            ]
        )
    }
}
