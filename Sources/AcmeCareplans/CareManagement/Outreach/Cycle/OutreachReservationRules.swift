import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a outreach reservation must pass. Check returns its problems, or none.
    protocol OutreachReservationRule {
        func check(_ item: OutreachReservation) -> [String]
    }

    final class OutreachReservationRequiredCodeRule: OutreachReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OutreachReservation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OutreachReservationCodeLengthRule: OutreachReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OutreachReservation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OutreachReservationExternalRefLengthRule: OutreachReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OutreachReservation) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OutreachReservationNotesLengthRule: OutreachReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OutreachReservation) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a outreach reservation.
    final class OutreachReservationValidator {
        var rules: [any OutreachReservationRule]

        init(rules: [any OutreachReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: OutreachReservation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: OutreachReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OutreachReservation]) -> [String: [String]] {
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

    static func defaultOutreachReservationValidator() -> OutreachReservationValidator {
        return OutreachReservationValidator(
            rules: [
                OutreachReservationRequiredCodeRule(message: "outreach reservation needs an entry"),
                OutreachReservationCodeLengthRule(maxLength: 16),
                OutreachReservationExternalRefLengthRule(maxLength: 1000),
                OutreachReservationNotesLengthRule(maxLength: 16),
            ]
        )
    }
}
