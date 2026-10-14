import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a overtime override must pass. Check returns its problems, or none.
    protocol OvertimeOverrideRule {
        func check(_ item: OvertimeOverride) -> [String]
    }

    final class OvertimeOverrideNameLengthRule: OvertimeOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OvertimeOverride) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OvertimeOverrideCreatedAtRangeRule: OvertimeOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OvertimeOverride) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class OvertimeOverrideRequiredNotesRule: OvertimeOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeOverride) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OvertimeOverrideCodeLengthRule: OvertimeOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OvertimeOverride) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a overtime override.
    final class OvertimeOverrideValidator {
        var rules: [any OvertimeOverrideRule]

        init(rules: [any OvertimeOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: OvertimeOverride) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: OvertimeOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OvertimeOverride]) -> [String: [String]] {
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

    static func defaultOvertimeOverrideValidator() -> OvertimeOverrideValidator {
        return OvertimeOverrideValidator(
            rules: [
                OvertimeOverrideNameLengthRule(maxLength: 255),
                OvertimeOverrideCreatedAtRangeRule(min: 3600, max: 86400),
                OvertimeOverrideRequiredNotesRule(message: "overtime override needs this field"),
                OvertimeOverrideCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
