import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a weighted transfer reservation must pass. Check returns its problems, or none.
    protocol WeightedTransferReservationRule {
        func check(_ item: WeightedTransferReservation) -> [String]
    }

    final class WeightedTransferReservationTitleLengthRule: WeightedTransferReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedTransferReservation) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedTransferReservationRequiredUnitRule: WeightedTransferReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedTransferReservation) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedTransferReservationLocaleLengthRule: WeightedTransferReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedTransferReservation) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedTransferReservationCodePrefixRule: WeightedTransferReservationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WeightedTransferReservation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WeightedTransferReservationRequiredLocaleRule: WeightedTransferReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedTransferReservation) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedTransferReservationRequiredCodeRule: WeightedTransferReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedTransferReservation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted transfer reservation.
    final class WeightedTransferReservationValidator {
        var rules: [any WeightedTransferReservationRule]

        init(rules: [any WeightedTransferReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedTransferReservation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedTransferReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedTransferReservation]) -> [String: [String]] {
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

    static func defaultWeightedTransferReservationValidator() -> WeightedTransferReservationValidator {
        return WeightedTransferReservationValidator(
            rules: [
                WeightedTransferReservationTitleLengthRule(maxLength: 120),
                WeightedTransferReservationRequiredUnitRule(message: "weighted transfer reservation needs a value"),
                WeightedTransferReservationLocaleLengthRule(maxLength: 255),
                WeightedTransferReservationCodePrefixRule(prefix: "Q"),
                WeightedTransferReservationRequiredLocaleRule(message: "weighted transfer reservation needs an entry"),
                WeightedTransferReservationRequiredCodeRule(message: "weighted transfer reservation needs a value"),
            ]
        )
    }
}
