import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a regional acuity plan reservation must pass. Check returns its problems, or none.
    protocol RegionalAcuityPlanReservationRule {
        func check(_ item: RegionalAcuityPlanReservation) -> [String]
    }

    final class RegionalAcuityPlanReservationCurrencyLengthRule: RegionalAcuityPlanReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalAcuityPlanReservation) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalAcuityPlanReservationApprovedGuardRule: RegionalAcuityPlanReservationRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: RegionalAcuityPlanReservation) -> [String] {
            if item.approved && (item.ceiling > limit) {
                return ["ceiling \(item.ceiling) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class RegionalAcuityPlanReservationDescriptionLengthRule: RegionalAcuityPlanReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalAcuityPlanReservation) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalAcuityPlanReservationRequiredCurrencyRule: RegionalAcuityPlanReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalAcuityPlanReservation) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalAcuityPlanReservationAllowedCurrencyRule: RegionalAcuityPlanReservationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalAcuityPlanReservation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.currency)) {
                return ["currency \(item.currency) is missing"]
            }
            return []
        }
    }

    /// Runs every rule of a regional acuity plan reservation.
    final class RegionalAcuityPlanReservationValidator {
        var rules: [any RegionalAcuityPlanReservationRule]

        init(rules: [any RegionalAcuityPlanReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalAcuityPlanReservation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalAcuityPlanReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalAcuityPlanReservation]) -> [String: [String]] {
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

    static func defaultRegionalAcuityPlanReservationValidator() -> RegionalAcuityPlanReservationValidator {
        return RegionalAcuityPlanReservationValidator(
            rules: [
                RegionalAcuityPlanReservationCurrencyLengthRule(maxLength: 32),
                RegionalAcuityPlanReservationApprovedGuardRule(limit: 4.3),
                RegionalAcuityPlanReservationDescriptionLengthRule(maxLength: 64),
                RegionalAcuityPlanReservationRequiredCurrencyRule(
                    message: "regional acuity plan reservation needs an entry"
                ),
                RegionalAcuityPlanReservationAllowedCurrencyRule(allowed: ["fallback", "pending", "lenient"]),
            ]
        )
    }
}
