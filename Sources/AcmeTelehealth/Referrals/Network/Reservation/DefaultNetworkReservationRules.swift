import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a default network reservation must pass. Check returns its problems, or none.
    protocol DefaultNetworkReservationRule {
        func check(_ item: DefaultNetworkReservation) -> [String]
    }

    final class DefaultNetworkReservationRequiredCodeRule: DefaultNetworkReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultNetworkReservation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultNetworkReservationAllowedCodeRule: DefaultNetworkReservationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DefaultNetworkReservation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is too long"]
            }
            return []
        }
    }

    final class DefaultNetworkReservationVisitMinutesRangeRule: DefaultNetworkReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultNetworkReservation) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultNetworkReservationLabelLengthRule: DefaultNetworkReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultNetworkReservation) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultNetworkReservationCodeLengthRule: DefaultNetworkReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultNetworkReservation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultNetworkReservationRequiredClinicianIDRule: DefaultNetworkReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultNetworkReservation) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a default network reservation.
    final class DefaultNetworkReservationValidator {
        var rules: [any DefaultNetworkReservationRule]

        init(rules: [any DefaultNetworkReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultNetworkReservation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultNetworkReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultNetworkReservation]) -> [String: [String]] {
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

    static func defaultDefaultNetworkReservationValidator() -> DefaultNetworkReservationValidator {
        return DefaultNetworkReservationValidator(
            rules: [
                DefaultNetworkReservationRequiredCodeRule(message: "default network reservation needs this field"),
                DefaultNetworkReservationAllowedCodeRule(allowed: ["default", "weighted"]),
                DefaultNetworkReservationVisitMinutesRangeRule(min: 32, max: 64),
                DefaultNetworkReservationLabelLengthRule(maxLength: 80),
                DefaultNetworkReservationCodeLengthRule(maxLength: 1000),
                DefaultNetworkReservationRequiredClinicianIDRule(
                    message: "default network reservation needs this field"
                ),
            ]
        )
    }
}
