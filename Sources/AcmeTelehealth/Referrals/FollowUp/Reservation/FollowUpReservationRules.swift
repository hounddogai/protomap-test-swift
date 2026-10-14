import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a follow up reservation must pass. Check returns its problems, or none.
    protocol FollowUpReservationRule {
        func check(_ item: FollowUpReservation) -> [String]
    }

    final class FollowUpReservationCodePrefixRule: FollowUpReservationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FollowUpReservation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FollowUpReservationWardLengthRule: FollowUpReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpReservation) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FollowUpReservationTitleLengthRule: FollowUpReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpReservation) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FollowUpReservationRequiredWardRule: FollowUpReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FollowUpReservation) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FollowUpReservationNameLengthRule: FollowUpReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpReservation) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FollowUpReservationDiscountRangeRule: FollowUpReservationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FollowUpReservation) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a follow up reservation.
    final class FollowUpReservationValidator {
        var rules: [any FollowUpReservationRule]

        init(rules: [any FollowUpReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: FollowUpReservation) -> [String] {
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

        func requireValid(_ item: FollowUpReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FollowUpReservation]) -> [String: [String]] {
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

    static func defaultFollowUpReservationValidator() -> FollowUpReservationValidator {
        return FollowUpReservationValidator(
            rules: [
                FollowUpReservationCodePrefixRule(prefix: "X"),
                FollowUpReservationWardLengthRule(maxLength: 255),
                FollowUpReservationTitleLengthRule(maxLength: 80),
                FollowUpReservationRequiredWardRule(message: "follow up reservation needs a value"),
                FollowUpReservationNameLengthRule(maxLength: 16),
                FollowUpReservationDiscountRangeRule(min: 3.8, max: 4717.7),
            ]
        )
    }
}
