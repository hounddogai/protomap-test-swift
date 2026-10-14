import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a recall reservation must pass. Check returns its problems, or none.
    protocol RecallReservationRule {
        func check(_ item: RecallReservation) -> [String]
    }

    final class RecallReservationPatientRefLengthRule: RecallReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RecallReservation) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RecallReservationAmountRangeRule: RecallReservationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RecallReservation) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RecallReservationCodePrefixRule: RecallReservationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RecallReservation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RecallReservationRequiredRegionRule: RecallReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RecallReservation) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a recall reservation.
    final class RecallReservationValidator {
        var rules: [any RecallReservationRule]

        init(rules: [any RecallReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: RecallReservation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RecallReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RecallReservation]) -> [String: [String]] {
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

    static func defaultRecallReservationValidator() -> RecallReservationValidator {
        return RecallReservationValidator(
            rules: [
                RecallReservationPatientRefLengthRule(maxLength: 86400),
                RecallReservationAmountRangeRule(min: 3.3, max: 2746.3),
                RecallReservationCodePrefixRule(prefix: "OPS"),
                RecallReservationRequiredRegionRule(message: "recall reservation needs this field"),
            ]
        )
    }
}
