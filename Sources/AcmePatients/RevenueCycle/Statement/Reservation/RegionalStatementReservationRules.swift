import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a regional statement reservation must pass. Check returns its problems, or none.
    protocol RegionalStatementReservationRule {
        func check(_ item: RegionalStatementReservation) -> [String]
    }

    final class RegionalStatementReservationRequiredLabelRule: RegionalStatementReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalStatementReservation) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalStatementReservationLabelLengthRule: RegionalStatementReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalStatementReservation) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalStatementReservationArchivedGuardRule: RegionalStatementReservationRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: RegionalStatementReservation) -> [String] {
            if item.archived && (item.limit > limit) {
                return ["limit \(item.limit) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    /// Runs every rule of a regional statement reservation.
    final class RegionalStatementReservationValidator {
        var rules: [any RegionalStatementReservationRule]

        init(rules: [any RegionalStatementReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalStatementReservation) -> [String] {
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

        func requireValid(_ item: RegionalStatementReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalStatementReservation]) -> [String: [String]] {
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

    static func defaultRegionalStatementReservationValidator() -> RegionalStatementReservationValidator {
        return RegionalStatementReservationValidator(
            rules: [
                RegionalStatementReservationRequiredLabelRule(
                    message: "regional statement reservation needs this field"
                ),
                RegionalStatementReservationLabelLengthRule(maxLength: 1000),
                RegionalStatementReservationArchivedGuardRule(limit: 80),
            ]
        )
    }
}
