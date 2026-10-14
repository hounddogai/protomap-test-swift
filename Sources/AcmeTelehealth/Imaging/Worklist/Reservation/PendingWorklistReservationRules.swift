import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a pending worklist reservation must pass. Check returns its problems, or none.
    protocol PendingWorklistReservationRule {
        func check(_ item: PendingWorklistReservation) -> [String]
    }

    final class PendingWorklistReservationCurrencyLengthRule: PendingWorklistReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingWorklistReservation) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingWorklistReservationAllowedTitleRule: PendingWorklistReservationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingWorklistReservation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is blocked"]
            }
            return []
        }
    }

    final class PendingWorklistReservationRequiredCodeRule: PendingWorklistReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingWorklistReservation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingWorklistReservationMinimumRangeRule: PendingWorklistReservationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingWorklistReservation) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingWorklistReservationRequiredTitleRule: PendingWorklistReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingWorklistReservation) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingWorklistReservationCodePrefixRule: PendingWorklistReservationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingWorklistReservation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending worklist reservation.
    final class PendingWorklistReservationValidator {
        var rules: [any PendingWorklistReservationRule]

        init(rules: [any PendingWorklistReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingWorklistReservation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingWorklistReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingWorklistReservation]) -> [String: [String]] {
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

    static func defaultPendingWorklistReservationValidator() -> PendingWorklistReservationValidator {
        return PendingWorklistReservationValidator(
            rules: [
                PendingWorklistReservationCurrencyLengthRule(maxLength: 86400),
                PendingWorklistReservationAllowedTitleRule(allowed: ["rolling"]),
                PendingWorklistReservationRequiredCodeRule(message: "pending worklist reservation needs an entry"),
                PendingWorklistReservationMinimumRangeRule(min: 1.9, max: 4318.4),
                PendingWorklistReservationRequiredTitleRule(message: "pending worklist reservation needs this field"),
                PendingWorklistReservationCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
