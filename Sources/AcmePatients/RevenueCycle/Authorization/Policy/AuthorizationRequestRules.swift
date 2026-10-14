import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a authorization request must pass. Check returns its problems, or none.
    protocol AuthorizationRequestRule {
        func check(_ item: AuthorizationRequest) -> [String]
    }

    final class AuthorizationRequestLabelLengthRule: AuthorizationRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AuthorizationRequest) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AuthorizationRequestRequiredCodeRule: AuthorizationRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AuthorizationRequest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AuthorizationRequestWeightRangeRule: AuthorizationRequestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AuthorizationRequest) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AuthorizationRequestRequiredLabelRule: AuthorizationRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AuthorizationRequest) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AuthorizationRequestCodePrefixRule: AuthorizationRequestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AuthorizationRequest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AuthorizationRequestCodeLengthRule: AuthorizationRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AuthorizationRequest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a authorization request.
    final class AuthorizationRequestValidator {
        var rules: [any AuthorizationRequestRule]

        init(rules: [any AuthorizationRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: AuthorizationRequest) -> [String] {
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

        func requireValid(_ item: AuthorizationRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AuthorizationRequest]) -> [String: [String]] {
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

    static func defaultAuthorizationRequestValidator() -> AuthorizationRequestValidator {
        return AuthorizationRequestValidator(
            rules: [
                AuthorizationRequestLabelLengthRule(maxLength: 32),
                AuthorizationRequestRequiredCodeRule(message: "authorization request needs a value"),
                AuthorizationRequestWeightRangeRule(min: 8.4, max: 4360.3),
                AuthorizationRequestRequiredLabelRule(message: "authorization request needs this field"),
                AuthorizationRequestCodePrefixRule(prefix: "REF"),
                AuthorizationRequestCodeLengthRule(maxLength: 120),
            ]
        )
    }
}
