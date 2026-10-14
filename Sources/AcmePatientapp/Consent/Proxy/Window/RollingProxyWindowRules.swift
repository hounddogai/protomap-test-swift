import AcmePlatform
import Foundation

extension Consent {
    /// A rule a rolling proxy window must pass. Check returns its problems, or none.
    protocol RollingProxyWindowRule {
        func check(_ item: RollingProxyWindow) -> [String]
    }

    final class RollingProxyWindowRequiredCodeRule: RollingProxyWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingProxyWindow) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingProxyWindowCodeLengthRule: RollingProxyWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingProxyWindow) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingProxyWindowTitleLengthRule: RollingProxyWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingProxyWindow) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingProxyWindowQuantityRangeRule: RollingProxyWindowRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingProxyWindow) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingProxyWindowNameLengthRule: RollingProxyWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingProxyWindow) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingProxyWindowAmountRangeRule: RollingProxyWindowRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingProxyWindow) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling proxy window.
    final class RollingProxyWindowValidator {
        var rules: [any RollingProxyWindowRule]

        init(rules: [any RollingProxyWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingProxyWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingProxyWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingProxyWindow]) -> [String: [String]] {
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

    static func defaultRollingProxyWindowValidator() -> RollingProxyWindowValidator {
        return RollingProxyWindowValidator(
            rules: [
                RollingProxyWindowRequiredCodeRule(message: "rolling proxy window needs an entry"),
                RollingProxyWindowCodeLengthRule(maxLength: 32),
                RollingProxyWindowTitleLengthRule(maxLength: 1000),
                RollingProxyWindowQuantityRangeRule(min: 3600, max: 86400),
                RollingProxyWindowNameLengthRule(maxLength: 16),
                RollingProxyWindowAmountRangeRule(min: 3.8, max: 4938.5),
            ]
        )
    }
}
