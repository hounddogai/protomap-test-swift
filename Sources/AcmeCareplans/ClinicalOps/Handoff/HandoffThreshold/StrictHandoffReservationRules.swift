import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a strict handoff reservation must pass. Check returns its problems, or none.
    protocol StrictHandoffReservationRule {
        func check(_ item: StrictHandoffReservation) -> [String]
    }

    final class StrictHandoffReservationRequiredLabelRule: StrictHandoffReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictHandoffReservation) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictHandoffReservationRequiredNameRule: StrictHandoffReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictHandoffReservation) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictHandoffReservationCodePrefixRule: StrictHandoffReservationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StrictHandoffReservation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StrictHandoffReservationNameLengthRule: StrictHandoffReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictHandoffReservation) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictHandoffReservationRequiredCountryRule: StrictHandoffReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictHandoffReservation) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a strict handoff reservation.
    final class StrictHandoffReservationValidator {
        var rules: [any StrictHandoffReservationRule]

        init(rules: [any StrictHandoffReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictHandoffReservation) -> [String] {
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

        func requireValid(_ item: StrictHandoffReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictHandoffReservation]) -> [String: [String]] {
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

    static func defaultStrictHandoffReservationValidator() -> StrictHandoffReservationValidator {
        return StrictHandoffReservationValidator(
            rules: [
                StrictHandoffReservationRequiredLabelRule(message: "strict handoff reservation needs this field"),
                StrictHandoffReservationRequiredNameRule(message: "strict handoff reservation needs this field"),
                StrictHandoffReservationCodePrefixRule(prefix: "OPS"),
                StrictHandoffReservationNameLengthRule(maxLength: 3600),
                StrictHandoffReservationRequiredCountryRule(message: "strict handoff reservation needs an entry"),
            ]
        )
    }
}
