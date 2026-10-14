import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a pending read reservation must pass. Check returns its problems, or none.
    protocol PendingReadReservationRule {
        func check(_ item: PendingReadReservation) -> [String]
    }

    final class PendingReadReservationLabelLengthRule: PendingReadReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingReadReservation) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingReadReservationUpdatedAtRangeRule: PendingReadReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingReadReservation) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingReadReservationRequiredSpecialtyRule: PendingReadReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingReadReservation) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingReadReservationCodeLengthRule: PendingReadReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingReadReservation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending read reservation.
    final class PendingReadReservationValidator {
        var rules: [any PendingReadReservationRule]

        init(rules: [any PendingReadReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingReadReservation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingReadReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingReadReservation]) -> [String: [String]] {
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

    static func defaultPendingReadReservationValidator() -> PendingReadReservationValidator {
        return PendingReadReservationValidator(
            rules: [
                PendingReadReservationLabelLengthRule(maxLength: 16),
                PendingReadReservationUpdatedAtRangeRule(min: 120, max: 86400),
                PendingReadReservationRequiredSpecialtyRule(message: "pending read reservation needs an entry"),
                PendingReadReservationCodeLengthRule(maxLength: 80),
            ]
        )
    }
}
