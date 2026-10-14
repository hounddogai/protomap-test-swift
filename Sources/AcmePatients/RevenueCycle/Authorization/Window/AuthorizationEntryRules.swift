import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a authorization entry must pass. Check returns its problems, or none.
    protocol AuthorizationEntryRule {
        func check(_ item: AuthorizationEntry) -> [String]
    }

    final class AuthorizationEntryThresholdRangeRule: AuthorizationEntryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AuthorizationEntry) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AuthorizationEntryRequiredNameRule: AuthorizationEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AuthorizationEntry) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AuthorizationEntryAllowedNameRule: AuthorizationEntryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AuthorizationEntry) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is out of range"]
            }
            return []
        }
    }

    final class AuthorizationEntryRequiredFacilityRule: AuthorizationEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AuthorizationEntry) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AuthorizationEntryCodeLengthRule: AuthorizationEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AuthorizationEntry) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a authorization entry.
    final class AuthorizationEntryValidator {
        var rules: [any AuthorizationEntryRule]

        init(rules: [any AuthorizationEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: AuthorizationEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AuthorizationEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AuthorizationEntry]) -> [String: [String]] {
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

    static func defaultAuthorizationEntryValidator() -> AuthorizationEntryValidator {
        return AuthorizationEntryValidator(
            rules: [
                AuthorizationEntryThresholdRangeRule(min: 5.7, max: 349.4),
                AuthorizationEntryRequiredNameRule(message: "authorization entry needs an entry"),
                AuthorizationEntryAllowedNameRule(allowed: ["manual"]),
                AuthorizationEntryRequiredFacilityRule(message: "authorization entry needs this field"),
                AuthorizationEntryCodeLengthRule(maxLength: 32),
            ]
        )
    }
}
