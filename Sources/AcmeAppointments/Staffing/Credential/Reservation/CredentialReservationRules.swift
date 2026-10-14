import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a credential reservation must pass. Check returns its problems, or none.
    protocol CredentialReservationRule {
        func check(_ item: CredentialReservation) -> [String]
    }

    final class CredentialReservationEndsAtRangeRule: CredentialReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CredentialReservation) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CredentialReservationCodePrefixRule: CredentialReservationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CredentialReservation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CredentialReservationFloorValueRangeRule: CredentialReservationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CredentialReservation) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CredentialReservationRequiredTitleRule: CredentialReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialReservation) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CredentialReservationActiveGuardRule: CredentialReservationRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: CredentialReservation) -> [String] {
            if item.active && (item.floorValue > limit) {
                return ["floor value \(item.floorValue) exceeds \(limit) while active"]
            }
            return []
        }
    }

    /// Runs every rule of a credential reservation.
    final class CredentialReservationValidator {
        var rules: [any CredentialReservationRule]

        init(rules: [any CredentialReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: CredentialReservation) -> [String] {
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

        func requireValid(_ item: CredentialReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CredentialReservation]) -> [String: [String]] {
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

    static func defaultCredentialReservationValidator() -> CredentialReservationValidator {
        return CredentialReservationValidator(
            rules: [
                CredentialReservationEndsAtRangeRule(min: 16, max: 1000),
                CredentialReservationCodePrefixRule(prefix: "OPS"),
                CredentialReservationFloorValueRangeRule(min: 3.6, max: 4715.8),
                CredentialReservationRequiredTitleRule(message: "credential reservation needs an entry"),
                CredentialReservationActiveGuardRule(limit: 5.2),
            ]
        )
    }
}
