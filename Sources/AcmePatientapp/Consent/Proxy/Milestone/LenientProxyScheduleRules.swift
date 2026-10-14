import AcmePlatform
import Foundation

extension Consent {
    /// A rule a lenient proxy schedule must pass. Check returns its problems, or none.
    protocol LenientProxyScheduleRule {
        func check(_ item: LenientProxySchedule) -> [String]
    }

    final class LenientProxyScheduleCostRangeRule: LenientProxyScheduleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientProxySchedule) -> [String] {
            let value = item.cost
            var problems: [String] = []
            if value < min {
                problems.append("cost \(value) is below \(min)")
            }
            if value > max {
                problems.append("cost \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LenientProxyScheduleRetriesRangeRule: LenientProxyScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientProxySchedule) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LenientProxyScheduleCodeLengthRule: LenientProxyScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientProxySchedule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient proxy schedule.
    final class LenientProxyScheduleValidator {
        var rules: [any LenientProxyScheduleRule]

        init(rules: [any LenientProxyScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientProxySchedule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientProxySchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientProxySchedule]) -> [String: [String]] {
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

    static func defaultLenientProxyScheduleValidator() -> LenientProxyScheduleValidator {
        return LenientProxyScheduleValidator(
            rules: [
                LenientProxyScheduleCostRangeRule(min: 6.8, max: 4496.5),
                LenientProxyScheduleRetriesRangeRule(min: 120, max: 3600),
                LenientProxyScheduleCodeLengthRule(maxLength: 64),
            ]
        )
    }
}
