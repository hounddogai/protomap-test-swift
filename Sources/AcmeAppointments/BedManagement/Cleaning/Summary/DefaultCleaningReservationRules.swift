import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a default cleaning reservation must pass. Check returns its problems, or none.
    protocol DefaultCleaningReservationRule {
        func check(_ item: DefaultCleaningReservation) -> [String]
    }

    final class DefaultCleaningReservationChannelLengthRule: DefaultCleaningReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultCleaningReservation) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultCleaningReservationCostRangeRule: DefaultCleaningReservationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultCleaningReservation) -> [String] {
            let value = item.cost
            var problems: [String] = []
            if value < min {
                problems.append("cost \(value) is below \(min)")
            }
            if value > max {
                problems.append("cost \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DefaultCleaningReservationRequiredCodeRule: DefaultCleaningReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultCleaningReservation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a default cleaning reservation.
    final class DefaultCleaningReservationValidator {
        var rules: [any DefaultCleaningReservationRule]

        init(rules: [any DefaultCleaningReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultCleaningReservation) -> [String] {
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

        func requireValid(_ item: DefaultCleaningReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultCleaningReservation]) -> [String: [String]] {
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

    static func defaultDefaultCleaningReservationValidator() -> DefaultCleaningReservationValidator {
        return DefaultCleaningReservationValidator(
            rules: [
                DefaultCleaningReservationChannelLengthRule(maxLength: 86400),
                DefaultCleaningReservationCostRangeRule(min: 0.4, max: 1276.6),
                DefaultCleaningReservationRequiredCodeRule(message: "default cleaning reservation needs this field"),
            ]
        )
    }
}
