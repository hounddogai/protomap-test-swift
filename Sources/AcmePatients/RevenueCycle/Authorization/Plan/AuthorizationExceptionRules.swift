import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a authorization exception must pass. Check returns its problems, or none.
    protocol AuthorizationExceptionRule {
        func check(_ item: AuthorizationException) -> [String]
    }

    final class AuthorizationExceptionBatchSizeRangeRule: AuthorizationExceptionRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AuthorizationException) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AuthorizationExceptionTitleLengthRule: AuthorizationExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AuthorizationException) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AuthorizationExceptionAllergyLengthRule: AuthorizationExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AuthorizationException) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AuthorizationExceptionCodePrefixRule: AuthorizationExceptionRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AuthorizationException) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AuthorizationExceptionAmountRangeRule: AuthorizationExceptionRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AuthorizationException) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a authorization exception.
    final class AuthorizationExceptionValidator {
        var rules: [any AuthorizationExceptionRule]

        init(rules: [any AuthorizationExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: AuthorizationException) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AuthorizationException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AuthorizationException]) -> [String: [String]] {
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

    static func defaultAuthorizationExceptionValidator() -> AuthorizationExceptionValidator {
        return AuthorizationExceptionValidator(
            rules: [
                AuthorizationExceptionBatchSizeRangeRule(min: 16, max: 64),
                AuthorizationExceptionTitleLengthRule(maxLength: 64),
                AuthorizationExceptionAllergyLengthRule(maxLength: 80),
                AuthorizationExceptionCodePrefixRule(prefix: "X"),
                AuthorizationExceptionAmountRangeRule(min: 3.7, max: 1234.5),
            ]
        )
    }
}
