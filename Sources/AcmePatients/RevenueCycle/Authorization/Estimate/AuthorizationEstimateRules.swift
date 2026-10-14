import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a authorization estimate must pass. Check returns its problems, or none.
    protocol AuthorizationEstimateRule {
        func check(_ item: AuthorizationEstimate) -> [String]
    }

    final class AuthorizationEstimateCategoryLengthRule: AuthorizationEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AuthorizationEstimate) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AuthorizationEstimateNotesLengthRule: AuthorizationEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AuthorizationEstimate) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AuthorizationEstimateWeightRangeRule: AuthorizationEstimateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AuthorizationEstimate) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AuthorizationEstimateCodePrefixRule: AuthorizationEstimateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AuthorizationEstimate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AuthorizationEstimateRequiredTitleRule: AuthorizationEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AuthorizationEstimate) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a authorization estimate.
    final class AuthorizationEstimateValidator {
        var rules: [any AuthorizationEstimateRule]

        init(rules: [any AuthorizationEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: AuthorizationEstimate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AuthorizationEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AuthorizationEstimate]) -> [String: [String]] {
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

    static func defaultAuthorizationEstimateValidator() -> AuthorizationEstimateValidator {
        return AuthorizationEstimateValidator(
            rules: [
                AuthorizationEstimateCategoryLengthRule(maxLength: 16),
                AuthorizationEstimateNotesLengthRule(maxLength: 64),
                AuthorizationEstimateWeightRangeRule(min: 4.7, max: 4158.0),
                AuthorizationEstimateCodePrefixRule(prefix: "OPS"),
                AuthorizationEstimateRequiredTitleRule(message: "authorization estimate needs this field"),
            ]
        )
    }
}
