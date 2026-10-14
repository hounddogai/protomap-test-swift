import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a authorization allocation must pass. Check returns its problems, or none.
    protocol AuthorizationAllocationRule {
        func check(_ item: AuthorizationAllocation) -> [String]
    }

    final class AuthorizationAllocationRevisionRangeRule: AuthorizationAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AuthorizationAllocation) -> [String] {
            let value = item.revision
            var problems: [String] = []
            if value < min {
                problems.append("revision \(value) is below \(min)")
            }
            if value > max {
                problems.append("revision \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AuthorizationAllocationNameLengthRule: AuthorizationAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AuthorizationAllocation) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AuthorizationAllocationRequiredNotesRule: AuthorizationAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AuthorizationAllocation) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AuthorizationAllocationNotesLengthRule: AuthorizationAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AuthorizationAllocation) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AuthorizationAllocationAllowedNotesRule: AuthorizationAllocationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AuthorizationAllocation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.notes)) {
                return ["notes \(item.notes) is above maximum"]
            }
            return []
        }
    }

    /// Runs every rule of a authorization allocation.
    final class AuthorizationAllocationValidator {
        var rules: [any AuthorizationAllocationRule]

        init(rules: [any AuthorizationAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: AuthorizationAllocation) -> [String] {
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

        func requireValid(_ item: AuthorizationAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AuthorizationAllocation]) -> [String: [String]] {
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

    static func defaultAuthorizationAllocationValidator() -> AuthorizationAllocationValidator {
        return AuthorizationAllocationValidator(
            rules: [
                AuthorizationAllocationRevisionRangeRule(min: 32, max: 1000),
                AuthorizationAllocationNameLengthRule(maxLength: 86400),
                AuthorizationAllocationRequiredNotesRule(message: "authorization allocation needs an entry"),
                AuthorizationAllocationNotesLengthRule(maxLength: 1000),
                AuthorizationAllocationAllowedNotesRule(allowed: ["regional", "lenient"]),
            ]
        )
    }
}
