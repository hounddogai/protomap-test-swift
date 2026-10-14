import AcmePlatform
import Foundation

extension Consent {
    /// A rule a pending proxy schedule must pass. Check returns its problems, or none.
    protocol PendingProxyScheduleRule {
        func check(_ item: PendingProxySchedule) -> [String]
    }

    final class PendingProxyScheduleDurationMinutesRangeRule: PendingProxyScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingProxySchedule) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingProxyScheduleRequiredWardRule: PendingProxyScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingProxySchedule) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingProxyScheduleRequiredCurrencyRule: PendingProxyScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingProxySchedule) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingProxyScheduleCodeLengthRule: PendingProxyScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingProxySchedule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending proxy schedule.
    final class PendingProxyScheduleValidator {
        var rules: [any PendingProxyScheduleRule]

        init(rules: [any PendingProxyScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingProxySchedule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingProxySchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingProxySchedule]) -> [String: [String]] {
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

    static func defaultPendingProxyScheduleValidator() -> PendingProxyScheduleValidator {
        return PendingProxyScheduleValidator(
            rules: [
                PendingProxyScheduleDurationMinutesRangeRule(min: 64, max: 80),
                PendingProxyScheduleRequiredWardRule(message: "pending proxy schedule needs an entry"),
                PendingProxyScheduleRequiredCurrencyRule(message: "pending proxy schedule needs a value"),
                PendingProxyScheduleCodeLengthRule(maxLength: 1000),
            ]
        )
    }
}
