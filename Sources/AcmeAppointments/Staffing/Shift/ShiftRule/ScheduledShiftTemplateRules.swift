import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a scheduled shift template must pass. Check returns its problems, or none.
    protocol ScheduledShiftTemplateRule {
        func check(_ item: ScheduledShiftTemplate) -> [String]
    }

    final class ScheduledShiftTemplateCodeLengthRule: ScheduledShiftTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledShiftTemplate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledShiftTemplateRequiredCodeRule: ScheduledShiftTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledShiftTemplate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledShiftTemplateAllowedContactEmailRule: ScheduledShiftTemplateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledShiftTemplate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.contactEmail)) {
                return ["contact email \(item.contactEmail) is duplicated"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled shift template.
    final class ScheduledShiftTemplateValidator {
        var rules: [any ScheduledShiftTemplateRule]

        init(rules: [any ScheduledShiftTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledShiftTemplate) -> [String] {
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

        func requireValid(_ item: ScheduledShiftTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledShiftTemplate]) -> [String: [String]] {
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

    static func defaultScheduledShiftTemplateValidator() -> ScheduledShiftTemplateValidator {
        return ScheduledShiftTemplateValidator(
            rules: [
                ScheduledShiftTemplateCodeLengthRule(maxLength: 32),
                ScheduledShiftTemplateRequiredCodeRule(message: "scheduled shift template needs this field"),
                ScheduledShiftTemplateAllowedContactEmailRule(allowed: ["weighted"]),
            ]
        )
    }
}
