import AcmePlatform
import Foundation

extension Consent {
    /// A rule a regional disclosure reservation must pass. Check returns its problems, or none.
    protocol RegionalDisclosureReservationRule {
        func check(_ item: RegionalDisclosureReservation) -> [String]
    }

    final class RegionalDisclosureReservationFacilityLengthRule: RegionalDisclosureReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalDisclosureReservation) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalDisclosureReservationCopayRangeRule: RegionalDisclosureReservationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalDisclosureReservation) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalDisclosureReservationRequiredFacilityRule: RegionalDisclosureReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalDisclosureReservation) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalDisclosureReservationCodePrefixRule: RegionalDisclosureReservationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalDisclosureReservation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RegionalDisclosureReservationWeightRangeRule: RegionalDisclosureReservationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalDisclosureReservation) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalDisclosureReservationCurrencyLengthRule: RegionalDisclosureReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalDisclosureReservation) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional disclosure reservation.
    final class RegionalDisclosureReservationValidator {
        var rules: [any RegionalDisclosureReservationRule]

        init(rules: [any RegionalDisclosureReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalDisclosureReservation) -> [String] {
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

        func requireValid(_ item: RegionalDisclosureReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalDisclosureReservation]) -> [String: [String]] {
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

    static func defaultRegionalDisclosureReservationValidator() -> RegionalDisclosureReservationValidator {
        return RegionalDisclosureReservationValidator(
            rules: [
                RegionalDisclosureReservationFacilityLengthRule(maxLength: 16),
                RegionalDisclosureReservationCopayRangeRule(min: 6.5, max: 1105.6),
                RegionalDisclosureReservationRequiredFacilityRule(
                    message: "regional disclosure reservation needs a value"
                ),
                RegionalDisclosureReservationCodePrefixRule(prefix: "OPS"),
                RegionalDisclosureReservationWeightRangeRule(min: 3.6, max: 1073.6),
                RegionalDisclosureReservationCurrencyLengthRule(maxLength: 1000),
            ]
        )
    }
}
