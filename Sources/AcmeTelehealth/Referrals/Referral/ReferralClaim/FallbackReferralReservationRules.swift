import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a fallback referral reservation must pass. Check returns its problems, or none.
    protocol FallbackReferralReservationRule {
        func check(_ item: FallbackReferralReservation) -> [String]
    }

    final class FallbackReferralReservationRefillsRangeRule: FallbackReferralReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackReferralReservation) -> [String] {
            let value = item.refills
            var problems: [String] = []
            if value < min {
                problems.append("refills \(value) is below \(min)")
            }
            if value > max {
                problems.append("refills \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackReferralReservationAllowedFacilityRule: FallbackReferralReservationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackReferralReservation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.facility)) {
                return ["facility \(item.facility) is below minimum"]
            }
            return []
        }
    }

    final class FallbackReferralReservationCodeLengthRule: FallbackReferralReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackReferralReservation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackReferralReservationCreatedAtRangeRule: FallbackReferralReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackReferralReservation) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackReferralReservationFacilityLengthRule: FallbackReferralReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackReferralReservation) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackReferralReservationLimitRangeRule: FallbackReferralReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackReferralReservation) -> [String] {
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

    /// Runs every rule of a fallback referral reservation.
    final class FallbackReferralReservationValidator {
        var rules: [any FallbackReferralReservationRule]

        init(rules: [any FallbackReferralReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackReferralReservation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackReferralReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackReferralReservation]) -> [String: [String]] {
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

    static func defaultFallbackReferralReservationValidator() -> FallbackReferralReservationValidator {
        return FallbackReferralReservationValidator(
            rules: [
                FallbackReferralReservationRefillsRangeRule(min: 255, max: 3600),
                FallbackReferralReservationAllowedFacilityRule(allowed: []),
                FallbackReferralReservationCodeLengthRule(maxLength: 3600),
                FallbackReferralReservationCreatedAtRangeRule(min: 80, max: 120),
                FallbackReferralReservationFacilityLengthRule(maxLength: 32),
                FallbackReferralReservationLimitRangeRule(min: 32, max: 1000),
            ]
        )
    }
}
