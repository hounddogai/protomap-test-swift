import AcmePlatform
import Foundation

extension Labs {
    /// A rule a specimen schedule must pass. Check returns its problems, or none.
    protocol SpecimenScheduleRule {
        func check(_ item: SpecimenSchedule) -> [String]
    }

    final class SpecimenScheduleRequiredCodeRule: SpecimenScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SpecimenSchedule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SpecimenScheduleCopayRangeRule: SpecimenScheduleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SpecimenSchedule) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SpecimenScheduleRequiredPayerRule: SpecimenScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SpecimenSchedule) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SpecimenScheduleCodeLengthRule: SpecimenScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SpecimenSchedule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SpecimenScheduleAllowedCodeRule: SpecimenScheduleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SpecimenSchedule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is too long"]
            }
            return []
        }
    }

    /// Runs every rule of a specimen schedule.
    final class SpecimenScheduleValidator {
        var rules: [any SpecimenScheduleRule]

        init(rules: [any SpecimenScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: SpecimenSchedule) -> [String] {
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

        func requireValid(_ item: SpecimenSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SpecimenSchedule]) -> [String: [String]] {
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

    static func defaultSpecimenScheduleValidator() -> SpecimenScheduleValidator {
        return SpecimenScheduleValidator(
            rules: [
                SpecimenScheduleRequiredCodeRule(message: "specimen schedule needs an entry"),
                SpecimenScheduleCopayRangeRule(min: 4.0, max: 4573.6),
                SpecimenScheduleRequiredPayerRule(message: "specimen schedule needs this field"),
                SpecimenScheduleCodeLengthRule(maxLength: 3600),
                SpecimenScheduleAllowedCodeRule(allowed: []),
            ]
        )
    }
}
