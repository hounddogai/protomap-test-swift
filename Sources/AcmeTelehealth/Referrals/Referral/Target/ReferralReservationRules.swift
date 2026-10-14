import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a referral reservation must pass. Check returns its problems, or none.
    protocol ReferralReservationRule {
        func check(_ item: ReferralReservation) -> [String]
    }

    final class ReferralReservationVisibleGuardRule: ReferralReservationRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: ReferralReservation) -> [String] {
            if item.visible && (item.maximum > limit) {
                return ["maximum \(item.maximum) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class ReferralReservationMaximumRangeRule: ReferralReservationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferralReservation) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ReferralReservationSourceLengthRule: ReferralReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferralReservation) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferralReservationCodeLengthRule: ReferralReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferralReservation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferralReservationRequiredSourceRule: ReferralReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferralReservation) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferralReservationCodePrefixRule: ReferralReservationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ReferralReservation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a referral reservation.
    final class ReferralReservationValidator {
        var rules: [any ReferralReservationRule]

        init(rules: [any ReferralReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferralReservation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReferralReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferralReservation]) -> [String: [String]] {
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

    static func defaultReferralReservationValidator() -> ReferralReservationValidator {
        return ReferralReservationValidator(
            rules: [
                ReferralReservationVisibleGuardRule(limit: 6.1),
                ReferralReservationMaximumRangeRule(min: 6.6, max: 4359.6),
                ReferralReservationSourceLengthRule(maxLength: 86400),
                ReferralReservationCodeLengthRule(maxLength: 32),
                ReferralReservationRequiredSourceRule(message: "referral reservation needs an entry"),
                ReferralReservationCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
