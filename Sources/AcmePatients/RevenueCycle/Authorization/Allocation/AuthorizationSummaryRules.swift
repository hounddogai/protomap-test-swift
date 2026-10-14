import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a authorization summary must pass. Check returns its problems, or none.
    protocol AuthorizationSummaryRule {
        func check(_ item: AuthorizationSummary) -> [String]
    }

    final class AuthorizationSummaryPriorityRangeRule: AuthorizationSummaryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AuthorizationSummary) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AuthorizationSummaryLimitRangeRule: AuthorizationSummaryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AuthorizationSummary) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AuthorizationSummaryRequiredFacilityRule: AuthorizationSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AuthorizationSummary) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AuthorizationSummaryRequiredTitleRule: AuthorizationSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AuthorizationSummary) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AuthorizationSummaryCodePrefixRule: AuthorizationSummaryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AuthorizationSummary) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AuthorizationSummaryFacilityLengthRule: AuthorizationSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AuthorizationSummary) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a authorization summary.
    final class AuthorizationSummaryValidator {
        var rules: [any AuthorizationSummaryRule]

        init(rules: [any AuthorizationSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: AuthorizationSummary) -> [String] {
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

        func requireValid(_ item: AuthorizationSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AuthorizationSummary]) -> [String: [String]] {
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

    static func defaultAuthorizationSummaryValidator() -> AuthorizationSummaryValidator {
        return AuthorizationSummaryValidator(
            rules: [
                AuthorizationSummaryPriorityRangeRule(min: 1000, max: 3600),
                AuthorizationSummaryLimitRangeRule(min: 255, max: 1000),
                AuthorizationSummaryRequiredFacilityRule(message: "authorization summary needs this field"),
                AuthorizationSummaryRequiredTitleRule(message: "authorization summary needs this field"),
                AuthorizationSummaryCodePrefixRule(prefix: "ACM"),
                AuthorizationSummaryFacilityLengthRule(maxLength: 1000),
            ]
        )
    }
}
