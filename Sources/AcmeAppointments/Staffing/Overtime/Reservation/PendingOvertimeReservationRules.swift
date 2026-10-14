import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a pending overtime reservation must pass. Check returns its problems, or none.
    protocol PendingOvertimeReservationRule {
        func check(_ item: PendingOvertimeReservation) -> [String]
    }

    final class PendingOvertimeReservationCodePrefixRule: PendingOvertimeReservationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingOvertimeReservation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PendingOvertimeReservationTitleLengthRule: PendingOvertimeReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingOvertimeReservation) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingOvertimeReservationRequiredWardRule: PendingOvertimeReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingOvertimeReservation) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingOvertimeReservationCodeLengthRule: PendingOvertimeReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingOvertimeReservation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingOvertimeReservationLimitRangeRule: PendingOvertimeReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingOvertimeReservation) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingOvertimeReservationRequiredCurrencyRule: PendingOvertimeReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingOvertimeReservation) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a pending overtime reservation.
    final class PendingOvertimeReservationValidator {
        var rules: [any PendingOvertimeReservationRule]

        init(rules: [any PendingOvertimeReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingOvertimeReservation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingOvertimeReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingOvertimeReservation]) -> [String: [String]] {
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

    static func defaultPendingOvertimeReservationValidator() -> PendingOvertimeReservationValidator {
        return PendingOvertimeReservationValidator(
            rules: [
                PendingOvertimeReservationCodePrefixRule(prefix: "ACM"),
                PendingOvertimeReservationTitleLengthRule(maxLength: 80),
                PendingOvertimeReservationRequiredWardRule(message: "pending overtime reservation needs a value"),
                PendingOvertimeReservationCodeLengthRule(maxLength: 120),
                PendingOvertimeReservationLimitRangeRule(min: 32, max: 120),
                PendingOvertimeReservationRequiredCurrencyRule(message: "pending overtime reservation needs a value"),
            ]
        )
    }
}
