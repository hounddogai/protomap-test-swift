import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a authorization assignment must pass. Check returns its problems, or none.
    protocol AuthorizationAssignmentRule {
        func check(_ item: AuthorizationAssignment) -> [String]
    }

    final class AuthorizationAssignmentCodeLengthRule: AuthorizationAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AuthorizationAssignment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AuthorizationAssignmentNameLengthRule: AuthorizationAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AuthorizationAssignment) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AuthorizationAssignmentRequiredFacilityRule: AuthorizationAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AuthorizationAssignment) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AuthorizationAssignmentRatioRangeRule: AuthorizationAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AuthorizationAssignment) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AuthorizationAssignmentAllowedNameRule: AuthorizationAssignmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AuthorizationAssignment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is unknown"]
            }
            return []
        }
    }

    final class AuthorizationAssignmentCodePrefixRule: AuthorizationAssignmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AuthorizationAssignment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a authorization assignment.
    final class AuthorizationAssignmentValidator {
        var rules: [any AuthorizationAssignmentRule]

        init(rules: [any AuthorizationAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: AuthorizationAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AuthorizationAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AuthorizationAssignment]) -> [String: [String]] {
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

    static func defaultAuthorizationAssignmentValidator() -> AuthorizationAssignmentValidator {
        return AuthorizationAssignmentValidator(
            rules: [
                AuthorizationAssignmentCodeLengthRule(maxLength: 64),
                AuthorizationAssignmentNameLengthRule(maxLength: 80),
                AuthorizationAssignmentRequiredFacilityRule(message: "authorization assignment needs this field"),
                AuthorizationAssignmentRatioRangeRule(min: 1.4, max: 1342.4),
                AuthorizationAssignmentAllowedNameRule(allowed: ["primary", "tiered", "pending"]),
                AuthorizationAssignmentCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
