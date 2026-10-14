import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a authorization mapping must pass. Check returns its problems, or none.
    protocol AuthorizationMappingRule {
        func check(_ item: AuthorizationMapping) -> [String]
    }

    final class AuthorizationMappingStartsAtRangeRule: AuthorizationMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AuthorizationMapping) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AuthorizationMappingRequiredCodeRule: AuthorizationMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AuthorizationMapping) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AuthorizationMappingExpiresAtRangeRule: AuthorizationMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AuthorizationMapping) -> [String] {
            let value = item.expiresAt
            var problems: [String] = []
            if value < min {
                problems.append("expires at \(value) is below \(min)")
            }
            if value > max {
                problems.append("expires at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AuthorizationMappingAllowedLabelRule: AuthorizationMappingRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AuthorizationMapping) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is missing"]
            }
            return []
        }
    }

    /// Runs every rule of a authorization mapping.
    final class AuthorizationMappingValidator {
        var rules: [any AuthorizationMappingRule]

        init(rules: [any AuthorizationMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: AuthorizationMapping) -> [String] {
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

        func requireValid(_ item: AuthorizationMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AuthorizationMapping]) -> [String: [String]] {
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

    static func defaultAuthorizationMappingValidator() -> AuthorizationMappingValidator {
        return AuthorizationMappingValidator(
            rules: [
                AuthorizationMappingStartsAtRangeRule(min: 16, max: 255),
                AuthorizationMappingRequiredCodeRule(message: "authorization mapping needs this field"),
                AuthorizationMappingExpiresAtRangeRule(min: 120, max: 255),
                AuthorizationMappingAllowedLabelRule(allowed: ["seasonal", "scheduled", "strict"]),
            ]
        )
    }
}
