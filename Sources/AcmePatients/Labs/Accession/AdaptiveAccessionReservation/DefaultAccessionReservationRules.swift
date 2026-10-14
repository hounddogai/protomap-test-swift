import AcmePlatform
import Foundation

extension Labs {
    /// A rule a default accession reservation must pass. Check returns its problems, or none.
    protocol DefaultAccessionReservationRule {
        func check(_ item: DefaultAccessionReservation) -> [String]
    }

    final class DefaultAccessionReservationRequiredPhoneRule: DefaultAccessionReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultAccessionReservation) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultAccessionReservationRequiredCurrencyRule: DefaultAccessionReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultAccessionReservation) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultAccessionReservationAllowedCurrencyRule: DefaultAccessionReservationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DefaultAccessionReservation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.currency)) {
                return ["currency \(item.currency) is not allowed"]
            }
            return []
        }
    }

    final class DefaultAccessionReservationRequiredCodeRule: DefaultAccessionReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultAccessionReservation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultAccessionReservationCurrencyLengthRule: DefaultAccessionReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultAccessionReservation) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultAccessionReservationPhoneLengthRule: DefaultAccessionReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultAccessionReservation) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a default accession reservation.
    final class DefaultAccessionReservationValidator {
        var rules: [any DefaultAccessionReservationRule]

        init(rules: [any DefaultAccessionReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultAccessionReservation) -> [String] {
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

        func requireValid(_ item: DefaultAccessionReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultAccessionReservation]) -> [String: [String]] {
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

    static func defaultDefaultAccessionReservationValidator() -> DefaultAccessionReservationValidator {
        return DefaultAccessionReservationValidator(
            rules: [
                DefaultAccessionReservationRequiredPhoneRule(message: "default accession reservation needs an entry"),
                DefaultAccessionReservationRequiredCurrencyRule(
                    message: "default accession reservation needs a value"
                ),
                DefaultAccessionReservationAllowedCurrencyRule(allowed: ["fallback", "lenient"]),
                DefaultAccessionReservationRequiredCodeRule(message: "default accession reservation needs an entry"),
                DefaultAccessionReservationCurrencyLengthRule(maxLength: 120),
                DefaultAccessionReservationPhoneLengthRule(maxLength: 120),
            ]
        )
    }
}
