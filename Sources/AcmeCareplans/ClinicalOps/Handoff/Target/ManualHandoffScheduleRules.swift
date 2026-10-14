import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a manual handoff schedule must pass. Check returns its problems, or none.
    protocol ManualHandoffScheduleRule {
        func check(_ item: ManualHandoffSchedule) -> [String]
    }

    final class ManualHandoffScheduleRequiredLabelRule: ManualHandoffScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualHandoffSchedule) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualHandoffScheduleBedLengthRule: ManualHandoffScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualHandoffSchedule) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualHandoffScheduleRequiredBedRule: ManualHandoffScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualHandoffSchedule) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualHandoffScheduleCodeLengthRule: ManualHandoffScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualHandoffSchedule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualHandoffScheduleRequiredCodeRule: ManualHandoffScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualHandoffSchedule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a manual handoff schedule.
    final class ManualHandoffScheduleValidator {
        var rules: [any ManualHandoffScheduleRule]

        init(rules: [any ManualHandoffScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualHandoffSchedule) -> [String] {
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

        func requireValid(_ item: ManualHandoffSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualHandoffSchedule]) -> [String: [String]] {
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

    static func defaultManualHandoffScheduleValidator() -> ManualHandoffScheduleValidator {
        return ManualHandoffScheduleValidator(
            rules: [
                ManualHandoffScheduleRequiredLabelRule(message: "manual handoff schedule needs an entry"),
                ManualHandoffScheduleBedLengthRule(maxLength: 80),
                ManualHandoffScheduleRequiredBedRule(message: "manual handoff schedule needs a value"),
                ManualHandoffScheduleCodeLengthRule(maxLength: 32),
                ManualHandoffScheduleRequiredCodeRule(message: "manual handoff schedule needs an entry"),
            ]
        )
    }
}
