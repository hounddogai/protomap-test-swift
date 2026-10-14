import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a capped claim reservation must pass. Check returns its problems, or none.
    protocol CappedClaimReservationRule {
        func check(_ item: CappedClaimReservation) -> [String]
    }

    final class CappedClaimReservationCodeLengthRule: CappedClaimReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedClaimReservation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedClaimReservationLabelLengthRule: CappedClaimReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedClaimReservation) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedClaimReservationCurrencyLengthRule: CappedClaimReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedClaimReservation) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedClaimReservationAmountRangeRule: CappedClaimReservationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedClaimReservation) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedClaimReservationAllowedEncounterIDRule: CappedClaimReservationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedClaimReservation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.encounterID)) {
                return ["encounter id \(item.encounterID) is missing"]
            }
            return []
        }
    }

    /// Runs every rule of a capped claim reservation.
    final class CappedClaimReservationValidator {
        var rules: [any CappedClaimReservationRule]

        init(rules: [any CappedClaimReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedClaimReservation) -> [String] {
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

        func requireValid(_ item: CappedClaimReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedClaimReservation]) -> [String: [String]] {
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

    static func defaultCappedClaimReservationValidator() -> CappedClaimReservationValidator {
        return CappedClaimReservationValidator(
            rules: [
                CappedClaimReservationCodeLengthRule(maxLength: 32),
                CappedClaimReservationLabelLengthRule(maxLength: 120),
                CappedClaimReservationCurrencyLengthRule(maxLength: 80),
                CappedClaimReservationAmountRangeRule(min: 4.0, max: 2418.5),
                CappedClaimReservationAllowedEncounterIDRule(allowed: []),
            ]
        )
    }
}
