import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a dispense schedule must pass. Check returns its problems, or none.
    protocol DispenseScheduleRule {
        func check(_ item: DispenseSchedule) -> [String]
    }

    final class DispenseScheduleRequiredUnitRule: DispenseScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DispenseSchedule) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DispenseScheduleAllowedLabelRule: DispenseScheduleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DispenseSchedule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is missing"]
            }
            return []
        }
    }

    final class DispenseScheduleUnitLengthRule: DispenseScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DispenseSchedule) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a dispense schedule.
    final class DispenseScheduleValidator {
        var rules: [any DispenseScheduleRule]

        init(rules: [any DispenseScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: DispenseSchedule) -> [String] {
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

        func requireValid(_ item: DispenseSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DispenseSchedule]) -> [String: [String]] {
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

    static func defaultDispenseScheduleValidator() -> DispenseScheduleValidator {
        return DispenseScheduleValidator(
            rules: [
                DispenseScheduleRequiredUnitRule(message: "dispense schedule needs this field"),
                DispenseScheduleAllowedLabelRule(allowed: ["rolling", "lenient", "strict"]),
                DispenseScheduleUnitLengthRule(maxLength: 32),
            ]
        )
    }
}
