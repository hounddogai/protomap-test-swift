import AcmePlatform
import Foundation

extension Labs {
    /// A rule a panel schedule must pass. Check returns its problems, or none.
    protocol PanelScheduleRule {
        func check(_ item: PanelSchedule) -> [String]
    }

    final class PanelScheduleTimezoneLengthRule: PanelScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PanelSchedule) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PanelScheduleRequiredTimezoneRule: PanelScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelSchedule) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PanelScheduleCodePrefixRule: PanelScheduleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PanelSchedule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a panel schedule.
    final class PanelScheduleValidator {
        var rules: [any PanelScheduleRule]

        init(rules: [any PanelScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: PanelSchedule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PanelSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PanelSchedule]) -> [String: [String]] {
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

    static func defaultPanelScheduleValidator() -> PanelScheduleValidator {
        return PanelScheduleValidator(
            rules: [
                PanelScheduleTimezoneLengthRule(maxLength: 255),
                PanelScheduleRequiredTimezoneRule(message: "panel schedule needs an entry"),
                PanelScheduleCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
