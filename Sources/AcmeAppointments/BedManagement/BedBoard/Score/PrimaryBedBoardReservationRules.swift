import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a primary bed board reservation must pass. Check returns its problems, or none.
    protocol PrimaryBedBoardReservationRule {
        func check(_ item: PrimaryBedBoardReservation) -> [String]
    }

    final class PrimaryBedBoardReservationAttemptsRangeRule: PrimaryBedBoardReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryBedBoardReservation) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryBedBoardReservationRequiredCurrencyRule: PrimaryBedBoardReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryBedBoardReservation) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryBedBoardReservationCodePrefixRule: PrimaryBedBoardReservationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryBedBoardReservation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PrimaryBedBoardReservationRequiredCodeRule: PrimaryBedBoardReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryBedBoardReservation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a primary bed board reservation.
    final class PrimaryBedBoardReservationValidator {
        var rules: [any PrimaryBedBoardReservationRule]

        init(rules: [any PrimaryBedBoardReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryBedBoardReservation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryBedBoardReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryBedBoardReservation]) -> [String: [String]] {
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

    static func defaultPrimaryBedBoardReservationValidator() -> PrimaryBedBoardReservationValidator {
        return PrimaryBedBoardReservationValidator(
            rules: [
                PrimaryBedBoardReservationAttemptsRangeRule(min: 16, max: 16),
                PrimaryBedBoardReservationRequiredCurrencyRule(message: "primary bed board reservation needs a value"),
                PrimaryBedBoardReservationCodePrefixRule(prefix: "X"),
                PrimaryBedBoardReservationRequiredCodeRule(message: "primary bed board reservation needs an entry"),
            ]
        )
    }
}
