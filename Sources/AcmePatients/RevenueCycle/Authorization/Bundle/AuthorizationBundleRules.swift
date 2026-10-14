import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a authorization bundle must pass. Check returns its problems, or none.
    protocol AuthorizationBundleRule {
        func check(_ item: AuthorizationBundle) -> [String]
    }

    final class AuthorizationBundleApprovedGuardRule: AuthorizationBundleRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: AuthorizationBundle) -> [String] {
            if item.approved && (item.createdAt > limit) {
                return ["created at \(item.createdAt) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class AuthorizationBundleCreatedAtRangeRule: AuthorizationBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AuthorizationBundle) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AuthorizationBundleRequiredCodeRule: AuthorizationBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AuthorizationBundle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AuthorizationBundleSpecialtyLengthRule: AuthorizationBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AuthorizationBundle) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AuthorizationBundleCodeLengthRule: AuthorizationBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AuthorizationBundle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AuthorizationBundleTitleLengthRule: AuthorizationBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AuthorizationBundle) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a authorization bundle.
    final class AuthorizationBundleValidator {
        var rules: [any AuthorizationBundleRule]

        init(rules: [any AuthorizationBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: AuthorizationBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AuthorizationBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AuthorizationBundle]) -> [String: [String]] {
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

    static func defaultAuthorizationBundleValidator() -> AuthorizationBundleValidator {
        return AuthorizationBundleValidator(
            rules: [
                AuthorizationBundleApprovedGuardRule(limit: 255),
                AuthorizationBundleCreatedAtRangeRule(min: 32, max: 86400),
                AuthorizationBundleRequiredCodeRule(message: "authorization bundle needs an entry"),
                AuthorizationBundleSpecialtyLengthRule(maxLength: 3600),
                AuthorizationBundleCodeLengthRule(maxLength: 16),
                AuthorizationBundleTitleLengthRule(maxLength: 32),
            ]
        )
    }
}
