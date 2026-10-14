import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a pending task schedule must pass. Check returns its problems, or none.
    protocol PendingTaskScheduleRule {
        func check(_ item: PendingTaskSchedule) -> [String]
    }

    final class PendingTaskScheduleAllergyLengthRule: PendingTaskScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingTaskSchedule) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingTaskScheduleRequiredCodeRule: PendingTaskScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingTaskSchedule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingTaskScheduleAllowedTitleRule: PendingTaskScheduleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingTaskSchedule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is too long"]
            }
            return []
        }
    }

    /// Runs every rule of a pending task schedule.
    final class PendingTaskScheduleValidator {
        var rules: [any PendingTaskScheduleRule]

        init(rules: [any PendingTaskScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingTaskSchedule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingTaskSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingTaskSchedule]) -> [String: [String]] {
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

    static func defaultPendingTaskScheduleValidator() -> PendingTaskScheduleValidator {
        return PendingTaskScheduleValidator(
            rules: [
                PendingTaskScheduleAllergyLengthRule(maxLength: 64),
                PendingTaskScheduleRequiredCodeRule(message: "pending task schedule needs an entry"),
                PendingTaskScheduleAllowedTitleRule(allowed: ["capped", "regional"]),
            ]
        )
    }
}
