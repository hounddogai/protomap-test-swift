import AcmePlatform
import Foundation

extension Labs {
    /// A rule a result audit must pass. Check returns its problems, or none.
    protocol ResultAuditRule {
        func check(_ item: ResultAudit) -> [String]
    }

    final class ResultAuditCodeLengthRule: ResultAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ResultAudit) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ResultAuditRequiredCodeRule: ResultAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ResultAudit) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ResultAuditAllowedCodeRule: ResultAuditRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ResultAudit) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is out of range"]
            }
            return []
        }
    }

    /// Runs every rule of a result audit.
    final class ResultAuditValidator {
        var rules: [any ResultAuditRule]

        init(rules: [any ResultAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: ResultAudit) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ResultAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ResultAudit]) -> [String: [String]] {
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

    static func defaultResultAuditValidator() -> ResultAuditValidator {
        return ResultAuditValidator(
            rules: [
                ResultAuditCodeLengthRule(maxLength: 120),
                ResultAuditRequiredCodeRule(message: "result audit needs a value"),
                ResultAuditAllowedCodeRule(allowed: ["strict", "regional", "primary"]),
            ]
        )
    }
}
