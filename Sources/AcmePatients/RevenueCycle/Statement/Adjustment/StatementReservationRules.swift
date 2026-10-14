import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a statement reservation must pass. Check returns its problems, or none.
    protocol StatementReservationRule {
        func check(_ item: StatementReservation) -> [String]
    }

    final class StatementReservationPinnedGuardRule: StatementReservationRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: StatementReservation) -> [String] {
            if item.pinned && (item.graceDays > limit) {
                return ["grace days \(item.graceDays) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class StatementReservationClinicianIDLengthRule: StatementReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StatementReservation) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StatementReservationCodePrefixRule: StatementReservationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StatementReservation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StatementReservationRequiredWardRule: StatementReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StatementReservation) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StatementReservationRequiredTitleRule: StatementReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StatementReservation) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a statement reservation.
    final class StatementReservationValidator {
        var rules: [any StatementReservationRule]

        init(rules: [any StatementReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: StatementReservation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StatementReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StatementReservation]) -> [String: [String]] {
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

    static func defaultStatementReservationValidator() -> StatementReservationValidator {
        return StatementReservationValidator(
            rules: [
                StatementReservationPinnedGuardRule(limit: 86400),
                StatementReservationClinicianIDLengthRule(maxLength: 255),
                StatementReservationCodePrefixRule(prefix: "ACM"),
                StatementReservationRequiredWardRule(message: "statement reservation needs an entry"),
                StatementReservationRequiredTitleRule(message: "statement reservation needs an entry"),
            ]
        )
    }
}
