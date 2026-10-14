import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a rolling statement exception must pass. Check returns its problems, or none.
    protocol RollingStatementExceptionRule {
        func check(_ item: RollingStatementException) -> [String]
    }

    final class RollingStatementExceptionCapacityRangeRule: RollingStatementExceptionRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingStatementException) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingStatementExceptionLocaleLengthRule: RollingStatementExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingStatementException) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingStatementExceptionCodePrefixRule: RollingStatementExceptionRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingStatementException) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RollingStatementExceptionGraceDaysRangeRule: RollingStatementExceptionRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingStatementException) -> [String] {
            let value = item.graceDays
            var problems: [String] = []
            if value < min {
                problems.append("grace days \(value) is below \(min)")
            }
            if value > max {
                problems.append("grace days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingStatementExceptionAllowedLocaleRule: RollingStatementExceptionRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingStatementException) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.locale)) {
                return ["locale \(item.locale) is missing"]
            }
            return []
        }
    }

    final class RollingStatementExceptionRatioRangeRule: RollingStatementExceptionRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingStatementException) -> [String] {
            let value = item.ratio
            var problems: [String] = []
            if value < min {
                problems.append("ratio \(value) is below \(min)")
            }
            if value > max {
                problems.append("ratio \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a rolling statement exception.
    final class RollingStatementExceptionValidator {
        var rules: [any RollingStatementExceptionRule]

        init(rules: [any RollingStatementExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingStatementException) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingStatementException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingStatementException]) -> [String: [String]] {
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

    static func defaultRollingStatementExceptionValidator() -> RollingStatementExceptionValidator {
        return RollingStatementExceptionValidator(
            rules: [
                RollingStatementExceptionCapacityRangeRule(min: 80, max: 120),
                RollingStatementExceptionLocaleLengthRule(maxLength: 16),
                RollingStatementExceptionCodePrefixRule(prefix: "Q"),
                RollingStatementExceptionGraceDaysRangeRule(min: 255, max: 3600),
                RollingStatementExceptionAllowedLocaleRule(allowed: ["primary"]),
                RollingStatementExceptionRatioRangeRule(min: 4.9, max: 3747.8),
            ]
        )
    }
}
