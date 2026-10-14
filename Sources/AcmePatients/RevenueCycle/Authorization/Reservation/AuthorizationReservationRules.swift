import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a authorization reservation must pass. Check returns its problems, or none.
    protocol AuthorizationReservationRule {
        func check(_ item: AuthorizationReservation) -> [String]
    }

    final class AuthorizationReservationRequiredCodeRule: AuthorizationReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AuthorizationReservation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AuthorizationReservationCodePrefixRule: AuthorizationReservationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AuthorizationReservation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AuthorizationReservationVersionRangeRule: AuthorizationReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AuthorizationReservation) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AuthorizationReservationRequiredTitleRule: AuthorizationReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AuthorizationReservation) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AuthorizationReservationTitleLengthRule: AuthorizationReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AuthorizationReservation) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a authorization reservation.
    final class AuthorizationReservationValidator {
        var rules: [any AuthorizationReservationRule]

        init(rules: [any AuthorizationReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: AuthorizationReservation) -> [String] {
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

        func requireValid(_ item: AuthorizationReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AuthorizationReservation]) -> [String: [String]] {
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

    static func defaultAuthorizationReservationValidator() -> AuthorizationReservationValidator {
        return AuthorizationReservationValidator(
            rules: [
                AuthorizationReservationRequiredCodeRule(message: "authorization reservation needs an entry"),
                AuthorizationReservationCodePrefixRule(prefix: "REF"),
                AuthorizationReservationVersionRangeRule(min: 255, max: 86400),
                AuthorizationReservationRequiredTitleRule(message: "authorization reservation needs a value"),
                AuthorizationReservationTitleLengthRule(maxLength: 86400),
            ]
        )
    }
}
