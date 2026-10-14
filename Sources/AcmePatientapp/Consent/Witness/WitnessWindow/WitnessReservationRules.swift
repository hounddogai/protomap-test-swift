import AcmePlatform
import Foundation

extension Consent {
    /// A rule a witness reservation must pass. Check returns its problems, or none.
    protocol WitnessReservationRule {
        func check(_ item: WitnessReservation) -> [String]
    }

    final class WitnessReservationAllowedCodeRule: WitnessReservationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WitnessReservation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is below minimum"]
            }
            return []
        }
    }

    final class WitnessReservationOwnerIDLengthRule: WitnessReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WitnessReservation) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WitnessReservationCeilingRangeRule: WitnessReservationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WitnessReservation) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WitnessReservationCopayRangeRule: WitnessReservationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WitnessReservation) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WitnessReservationRequiredLabelRule: WitnessReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WitnessReservation) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a witness reservation.
    final class WitnessReservationValidator {
        var rules: [any WitnessReservationRule]

        init(rules: [any WitnessReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: WitnessReservation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WitnessReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WitnessReservation]) -> [String: [String]] {
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

    static func defaultWitnessReservationValidator() -> WitnessReservationValidator {
        return WitnessReservationValidator(
            rules: [
                WitnessReservationAllowedCodeRule(allowed: []),
                WitnessReservationOwnerIDLengthRule(maxLength: 80),
                WitnessReservationCeilingRangeRule(min: 5.2, max: 2122.5),
                WitnessReservationCopayRangeRule(min: 9.5, max: 2252.5),
                WitnessReservationRequiredLabelRule(message: "witness reservation needs a value"),
            ]
        )
    }
}
