import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a float pool schedule must pass. Check returns its problems, or none.
    protocol FloatPoolScheduleRule {
        func check(_ item: FloatPoolSchedule) -> [String]
    }

    final class FloatPoolScheduleAllowedCodeRule: FloatPoolScheduleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FloatPoolSchedule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is not allowed"]
            }
            return []
        }
    }

    final class FloatPoolScheduleRequiredCodeRule: FloatPoolScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FloatPoolSchedule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FloatPoolScheduleNameLengthRule: FloatPoolScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FloatPoolSchedule) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a float pool schedule.
    final class FloatPoolScheduleValidator {
        var rules: [any FloatPoolScheduleRule]

        init(rules: [any FloatPoolScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: FloatPoolSchedule) -> [String] {
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

        func requireValid(_ item: FloatPoolSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FloatPoolSchedule]) -> [String: [String]] {
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

    static func defaultFloatPoolScheduleValidator() -> FloatPoolScheduleValidator {
        return FloatPoolScheduleValidator(
            rules: [
                FloatPoolScheduleAllowedCodeRule(allowed: ["adaptive", "weighted"]),
                FloatPoolScheduleRequiredCodeRule(message: "float pool schedule needs an entry"),
                FloatPoolScheduleNameLengthRule(maxLength: 3600),
            ]
        )
    }
}
