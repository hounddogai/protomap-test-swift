import AcmePlatform
import Foundation

extension Labs {
    /// A rule a adaptive specimen schedule must pass. Check returns its problems, or none.
    protocol AdaptiveSpecimenScheduleRule {
        func check(_ item: AdaptiveSpecimenSchedule) -> [String]
    }

    final class AdaptiveSpecimenScheduleNameLengthRule: AdaptiveSpecimenScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveSpecimenSchedule) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveSpecimenScheduleCodeLengthRule: AdaptiveSpecimenScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveSpecimenSchedule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveSpecimenScheduleRequiredCategoryRule: AdaptiveSpecimenScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveSpecimenSchedule) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveSpecimenScheduleRequiredNameRule: AdaptiveSpecimenScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveSpecimenSchedule) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveSpecimenScheduleRequiredProcedureCodeRule: AdaptiveSpecimenScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveSpecimenSchedule) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveSpecimenScheduleCeilingRangeRule: AdaptiveSpecimenScheduleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveSpecimenSchedule) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive specimen schedule.
    final class AdaptiveSpecimenScheduleValidator {
        var rules: [any AdaptiveSpecimenScheduleRule]

        init(rules: [any AdaptiveSpecimenScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveSpecimenSchedule) -> [String] {
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

        func requireValid(_ item: AdaptiveSpecimenSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveSpecimenSchedule]) -> [String: [String]] {
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

    static func defaultAdaptiveSpecimenScheduleValidator() -> AdaptiveSpecimenScheduleValidator {
        return AdaptiveSpecimenScheduleValidator(
            rules: [
                AdaptiveSpecimenScheduleNameLengthRule(maxLength: 32),
                AdaptiveSpecimenScheduleCodeLengthRule(maxLength: 120),
                AdaptiveSpecimenScheduleRequiredCategoryRule(message: "adaptive specimen schedule needs a value"),
                AdaptiveSpecimenScheduleRequiredNameRule(message: "adaptive specimen schedule needs this field"),
                AdaptiveSpecimenScheduleRequiredProcedureCodeRule(message: "adaptive specimen schedule needs a value"),
                AdaptiveSpecimenScheduleCeilingRangeRule(min: 9.5, max: 2244.1),
            ]
        )
    }
}
