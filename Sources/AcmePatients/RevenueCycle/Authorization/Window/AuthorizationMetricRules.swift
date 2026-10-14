import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a authorization metric must pass. Check returns its problems, or none.
    protocol AuthorizationMetricRule {
        func check(_ item: AuthorizationMetric) -> [String]
    }

    final class AuthorizationMetricRequiredCodeRule: AuthorizationMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AuthorizationMetric) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AuthorizationMetricGraceDaysRangeRule: AuthorizationMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AuthorizationMetric) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AuthorizationMetricCategoryLengthRule: AuthorizationMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AuthorizationMetric) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AuthorizationMetricCodePrefixRule: AuthorizationMetricRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AuthorizationMetric) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AuthorizationMetricRequiredCategoryRule: AuthorizationMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AuthorizationMetric) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AuthorizationMetricCodeLengthRule: AuthorizationMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AuthorizationMetric) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a authorization metric.
    final class AuthorizationMetricValidator {
        var rules: [any AuthorizationMetricRule]

        init(rules: [any AuthorizationMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: AuthorizationMetric) -> [String] {
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

        func requireValid(_ item: AuthorizationMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AuthorizationMetric]) -> [String: [String]] {
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

    static func defaultAuthorizationMetricValidator() -> AuthorizationMetricValidator {
        return AuthorizationMetricValidator(
            rules: [
                AuthorizationMetricRequiredCodeRule(message: "authorization metric needs an entry"),
                AuthorizationMetricGraceDaysRangeRule(min: 32, max: 3600),
                AuthorizationMetricCategoryLengthRule(maxLength: 80),
                AuthorizationMetricCodePrefixRule(prefix: "ACM"),
                AuthorizationMetricRequiredCategoryRule(message: "authorization metric needs this field"),
                AuthorizationMetricCodeLengthRule(maxLength: 64),
            ]
        )
    }
}
