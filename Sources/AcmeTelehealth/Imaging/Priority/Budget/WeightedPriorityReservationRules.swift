import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a weighted priority reservation must pass. Check returns its problems, or none.
    protocol WeightedPriorityReservationRule {
        func check(_ item: WeightedPriorityReservation) -> [String]
    }

    final class WeightedPriorityReservationRequiredLabelRule: WeightedPriorityReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedPriorityReservation) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedPriorityReservationLabelLengthRule: WeightedPriorityReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedPriorityReservation) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedPriorityReservationTitleLengthRule: WeightedPriorityReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedPriorityReservation) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted priority reservation.
    final class WeightedPriorityReservationValidator {
        var rules: [any WeightedPriorityReservationRule]

        init(rules: [any WeightedPriorityReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedPriorityReservation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedPriorityReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedPriorityReservation]) -> [String: [String]] {
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

    static func defaultWeightedPriorityReservationValidator() -> WeightedPriorityReservationValidator {
        return WeightedPriorityReservationValidator(
            rules: [
                WeightedPriorityReservationRequiredLabelRule(message: "weighted priority reservation needs an entry"),
                WeightedPriorityReservationLabelLengthRule(maxLength: 3600),
                WeightedPriorityReservationTitleLengthRule(maxLength: 1000),
            ]
        )
    }
}
