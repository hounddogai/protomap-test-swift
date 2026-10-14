import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a pending claim reservation must pass. Check returns its problems, or none.
    protocol PendingClaimReservationRule {
        func check(_ item: PendingClaimReservation) -> [String]
    }

    final class PendingClaimReservationCopayRangeRule: PendingClaimReservationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingClaimReservation) -> [String] {
            let value = item.copay
            var problems: [String] = []
            if value < min {
                problems.append("copay \(value) is below \(min)")
            }
            if value > max {
                problems.append("copay \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingClaimReservationTimezoneLengthRule: PendingClaimReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingClaimReservation) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingClaimReservationCodePrefixRule: PendingClaimReservationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingClaimReservation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PendingClaimReservationContactEmailLengthRule: PendingClaimReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingClaimReservation) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingClaimReservationRequiredNameRule: PendingClaimReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingClaimReservation) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a pending claim reservation.
    final class PendingClaimReservationValidator {
        var rules: [any PendingClaimReservationRule]

        init(rules: [any PendingClaimReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingClaimReservation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingClaimReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingClaimReservation]) -> [String: [String]] {
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

    static func defaultPendingClaimReservationValidator() -> PendingClaimReservationValidator {
        return PendingClaimReservationValidator(
            rules: [
                PendingClaimReservationCopayRangeRule(min: 2.2, max: 252.7),
                PendingClaimReservationTimezoneLengthRule(maxLength: 3600),
                PendingClaimReservationCodePrefixRule(prefix: "ACM"),
                PendingClaimReservationContactEmailLengthRule(maxLength: 80),
                PendingClaimReservationRequiredNameRule(message: "pending claim reservation needs an entry"),
            ]
        )
    }
}
