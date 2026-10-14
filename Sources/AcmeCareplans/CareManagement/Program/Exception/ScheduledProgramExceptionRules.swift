import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a scheduled program exception must pass. Check returns its problems, or none.
    protocol ScheduledProgramExceptionRule {
        func check(_ item: ScheduledProgramException) -> [String]
    }

    final class ScheduledProgramExceptionAllowedWardRule: ScheduledProgramExceptionRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledProgramException) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ward)) {
                return ["ward \(item.ward) is stale"]
            }
            return []
        }
    }

    final class ScheduledProgramExceptionCodePrefixRule: ScheduledProgramExceptionRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledProgramException) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledProgramExceptionRequiredWardRule: ScheduledProgramExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledProgramException) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledProgramExceptionWardLengthRule: ScheduledProgramExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledProgramException) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled program exception.
    final class ScheduledProgramExceptionValidator {
        var rules: [any ScheduledProgramExceptionRule]

        init(rules: [any ScheduledProgramExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledProgramException) -> [String] {
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

        func requireValid(_ item: ScheduledProgramException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledProgramException]) -> [String: [String]] {
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

    static func defaultScheduledProgramExceptionValidator() -> ScheduledProgramExceptionValidator {
        return ScheduledProgramExceptionValidator(
            rules: [
                ScheduledProgramExceptionAllowedWardRule(allowed: ["seasonal", "regional"]),
                ScheduledProgramExceptionCodePrefixRule(prefix: "REF"),
                ScheduledProgramExceptionRequiredWardRule(message: "scheduled program exception needs a value"),
                ScheduledProgramExceptionWardLengthRule(maxLength: 3600),
            ]
        )
    }
}
