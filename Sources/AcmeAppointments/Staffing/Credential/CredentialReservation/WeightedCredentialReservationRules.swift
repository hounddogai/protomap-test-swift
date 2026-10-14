import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a weighted credential reservation must pass. Check returns its problems, or none.
    protocol WeightedCredentialReservationRule {
        func check(_ item: WeightedCredentialReservation) -> [String]
    }

    final class WeightedCredentialReservationPhoneLengthRule: WeightedCredentialReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedCredentialReservation) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedCredentialReservationCodeLengthRule: WeightedCredentialReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedCredentialReservation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedCredentialReservationRequiredCodeRule: WeightedCredentialReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedCredentialReservation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedCredentialReservationCodePrefixRule: WeightedCredentialReservationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WeightedCredentialReservation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WeightedCredentialReservationArchivedGuardRule: WeightedCredentialReservationRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: WeightedCredentialReservation) -> [String] {
            if item.archived && (item.maximum > limit) {
                return ["maximum \(item.maximum) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class WeightedCredentialReservationMaximumRangeRule: WeightedCredentialReservationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedCredentialReservation) -> [String] {
            let value = item.maximum
            var problems: [String] = []
            if value < min {
                problems.append("maximum \(value) is below \(min)")
            }
            if value > max {
                problems.append("maximum \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a weighted credential reservation.
    final class WeightedCredentialReservationValidator {
        var rules: [any WeightedCredentialReservationRule]

        init(rules: [any WeightedCredentialReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedCredentialReservation) -> [String] {
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

        func requireValid(_ item: WeightedCredentialReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedCredentialReservation]) -> [String: [String]] {
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

    static func defaultWeightedCredentialReservationValidator() -> WeightedCredentialReservationValidator {
        return WeightedCredentialReservationValidator(
            rules: [
                WeightedCredentialReservationPhoneLengthRule(maxLength: 16),
                WeightedCredentialReservationCodeLengthRule(maxLength: 1000),
                WeightedCredentialReservationRequiredCodeRule(
                    message: "weighted credential reservation needs a value"
                ),
                WeightedCredentialReservationCodePrefixRule(prefix: "REF"),
                WeightedCredentialReservationArchivedGuardRule(limit: 0.8),
                WeightedCredentialReservationMaximumRangeRule(min: 6.9, max: 1187.1),
            ]
        )
    }
}
