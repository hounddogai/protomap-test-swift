import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a lenient remittance reservation must pass. Check returns its problems, or none.
    protocol LenientRemittanceReservationRule {
        func check(_ item: LenientRemittanceReservation) -> [String]
    }

    final class LenientRemittanceReservationLimitRangeRule: LenientRemittanceReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientRemittanceReservation) -> [String] {
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

    final class LenientRemittanceReservationAcuityRangeRule: LenientRemittanceReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientRemittanceReservation) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientRemittanceReservationRequiredLabelRule: LenientRemittanceReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientRemittanceReservation) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientRemittanceReservationAllowedCodeRule: LenientRemittanceReservationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LenientRemittanceReservation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is inconsistent"]
            }
            return []
        }
    }

    final class LenientRemittanceReservationRequiredTimezoneRule: LenientRemittanceReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientRemittanceReservation) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a lenient remittance reservation.
    final class LenientRemittanceReservationValidator {
        var rules: [any LenientRemittanceReservationRule]

        init(rules: [any LenientRemittanceReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientRemittanceReservation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientRemittanceReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientRemittanceReservation]) -> [String: [String]] {
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

    static func defaultLenientRemittanceReservationValidator() -> LenientRemittanceReservationValidator {
        return LenientRemittanceReservationValidator(
            rules: [
                LenientRemittanceReservationLimitRangeRule(min: 80, max: 3600),
                LenientRemittanceReservationAcuityRangeRule(min: 32, max: 32),
                LenientRemittanceReservationRequiredLabelRule(message: "lenient remittance reservation needs a value"),
                LenientRemittanceReservationAllowedCodeRule(allowed: ["adaptive", "weighted"]),
                LenientRemittanceReservationRequiredTimezoneRule(
                    message: "lenient remittance reservation needs this field"
                ),
            ]
        )
    }
}
