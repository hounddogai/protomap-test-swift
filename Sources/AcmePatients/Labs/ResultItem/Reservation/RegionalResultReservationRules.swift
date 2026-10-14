import AcmePlatform
import Foundation

extension Labs {
    /// A rule a regional result reservation must pass. Check returns its problems, or none.
    protocol RegionalResultReservationRule {
        func check(_ item: RegionalResultReservation) -> [String]
    }

    final class RegionalResultReservationRequiredCurrencyRule: RegionalResultReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalResultReservation) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalResultReservationCodePrefixRule: RegionalResultReservationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalResultReservation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RegionalResultReservationLabelLengthRule: RegionalResultReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalResultReservation) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalResultReservationCurrencyLengthRule: RegionalResultReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalResultReservation) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalResultReservationRequiredTitleRule: RegionalResultReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalResultReservation) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalResultReservationAcuityRangeRule: RegionalResultReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalResultReservation) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional result reservation.
    final class RegionalResultReservationValidator {
        var rules: [any RegionalResultReservationRule]

        init(rules: [any RegionalResultReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalResultReservation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalResultReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalResultReservation]) -> [String: [String]] {
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

    static func defaultRegionalResultReservationValidator() -> RegionalResultReservationValidator {
        return RegionalResultReservationValidator(
            rules: [
                RegionalResultReservationRequiredCurrencyRule(message: "regional result reservation needs a value"),
                RegionalResultReservationCodePrefixRule(prefix: "ACM"),
                RegionalResultReservationLabelLengthRule(maxLength: 255),
                RegionalResultReservationCurrencyLengthRule(maxLength: 64),
                RegionalResultReservationRequiredTitleRule(message: "regional result reservation needs an entry"),
                RegionalResultReservationAcuityRangeRule(min: 32, max: 255),
            ]
        )
    }
}
