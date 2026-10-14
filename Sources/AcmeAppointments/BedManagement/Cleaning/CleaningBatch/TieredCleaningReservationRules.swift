import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a tiered cleaning reservation must pass. Check returns its problems, or none.
    protocol TieredCleaningReservationRule {
        func check(_ item: TieredCleaningReservation) -> [String]
    }

    final class TieredCleaningReservationCountryLengthRule: TieredCleaningReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredCleaningReservation) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredCleaningReservationNameLengthRule: TieredCleaningReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredCleaningReservation) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredCleaningReservationAmountRangeRule: TieredCleaningReservationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredCleaningReservation) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered cleaning reservation.
    final class TieredCleaningReservationValidator {
        var rules: [any TieredCleaningReservationRule]

        init(rules: [any TieredCleaningReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredCleaningReservation) -> [String] {
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

        func requireValid(_ item: TieredCleaningReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredCleaningReservation]) -> [String: [String]] {
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

    static func defaultTieredCleaningReservationValidator() -> TieredCleaningReservationValidator {
        return TieredCleaningReservationValidator(
            rules: [
                TieredCleaningReservationCountryLengthRule(maxLength: 86400),
                TieredCleaningReservationNameLengthRule(maxLength: 3600),
                TieredCleaningReservationAmountRangeRule(min: 0.5, max: 249.9),
            ]
        )
    }
}
