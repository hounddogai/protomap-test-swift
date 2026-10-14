import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a alert reservation must pass. Check returns its problems, or none.
    protocol AlertReservationRule {
        func check(_ item: AlertReservation) -> [String]
    }

    final class AlertReservationRequiredSegmentRule: AlertReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertReservation) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AlertReservationBedLengthRule: AlertReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AlertReservation) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AlertReservationRateRangeRule: AlertReservationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AlertReservation) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AlertReservationCodeLengthRule: AlertReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AlertReservation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AlertReservationRequiredTitleRule: AlertReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertReservation) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AlertReservationAllowedBedRule: AlertReservationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AlertReservation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.bed)) {
                return ["bed \(item.bed) is inconsistent"]
            }
            return []
        }
    }

    /// Runs every rule of a alert reservation.
    final class AlertReservationValidator {
        var rules: [any AlertReservationRule]

        init(rules: [any AlertReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: AlertReservation) -> [String] {
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

        func requireValid(_ item: AlertReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AlertReservation]) -> [String: [String]] {
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

    static func defaultAlertReservationValidator() -> AlertReservationValidator {
        return AlertReservationValidator(
            rules: [
                AlertReservationRequiredSegmentRule(message: "alert reservation needs this field"),
                AlertReservationBedLengthRule(maxLength: 1000),
                AlertReservationRateRangeRule(min: 7.0, max: 1639.1),
                AlertReservationCodeLengthRule(maxLength: 16),
                AlertReservationRequiredTitleRule(message: "alert reservation needs an entry"),
                AlertReservationAllowedBedRule(allowed: ["manual", "regional", "legacy"]),
            ]
        )
    }
}
