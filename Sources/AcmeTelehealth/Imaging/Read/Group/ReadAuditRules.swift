import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a read audit must pass. Check returns its problems, or none.
    protocol ReadAuditRule {
        func check(_ item: ReadAudit) -> [String]
    }

    final class ReadAuditRequiredTitleRule: ReadAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReadAudit) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReadAuditExpiresAtRangeRule: ReadAuditRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReadAudit) -> [String] {
            let value = item.expiresAt
            var problems: [String] = []
            if value < min {
                problems.append("expires at \(value) is below \(min)")
            }
            if value > max {
                problems.append("expires at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ReadAuditCodePrefixRule: ReadAuditRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ReadAudit) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ReadAuditRequiredCodeRule: ReadAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReadAudit) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a read audit.
    final class ReadAuditValidator {
        var rules: [any ReadAuditRule]

        init(rules: [any ReadAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: ReadAudit) -> [String] {
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

        func requireValid(_ item: ReadAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReadAudit]) -> [String: [String]] {
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

    static func defaultReadAuditValidator() -> ReadAuditValidator {
        return ReadAuditValidator(
            rules: [
                ReadAuditRequiredTitleRule(message: "read audit needs an entry"),
                ReadAuditExpiresAtRangeRule(min: 32, max: 80),
                ReadAuditCodePrefixRule(prefix: "X"),
                ReadAuditRequiredCodeRule(message: "read audit needs an entry"),
            ]
        )
    }
}
