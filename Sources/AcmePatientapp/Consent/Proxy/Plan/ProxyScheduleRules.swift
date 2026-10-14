import AcmePlatform
import Foundation

extension Consent {
    /// A rule a proxy schedule must pass. Check returns its problems, or none.
    protocol ProxyScheduleRule {
        func check(_ item: ProxySchedule) -> [String]
    }

    final class ProxyScheduleCodeLengthRule: ProxyScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProxySchedule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProxySchedulePriorityRangeRule: ProxyScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProxySchedule) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ProxyScheduleRequiredCurrencyRule: ProxyScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxySchedule) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a proxy schedule.
    final class ProxyScheduleValidator {
        var rules: [any ProxyScheduleRule]

        init(rules: [any ProxyScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: ProxySchedule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ProxySchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProxySchedule]) -> [String: [String]] {
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

    static func defaultProxyScheduleValidator() -> ProxyScheduleValidator {
        return ProxyScheduleValidator(
            rules: [
                ProxyScheduleCodeLengthRule(maxLength: 32),
                ProxySchedulePriorityRangeRule(min: 80, max: 1000),
                ProxyScheduleRequiredCurrencyRule(message: "proxy schedule needs an entry"),
            ]
        )
    }
}
