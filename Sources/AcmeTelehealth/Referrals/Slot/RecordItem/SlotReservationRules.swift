import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a slot reservation must pass. Check returns its problems, or none.
    protocol SlotReservationRule {
        func check(_ item: SlotReservation) -> [String]
    }

    final class SlotReservationWindowDaysRangeRule: SlotReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SlotReservation) -> [String] {
            let value = item.windowDays
            var problems: [String] = []
            if value < min {
                problems.append("window days \(value) is below \(min)")
            }
            if value > max {
                problems.append("window days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SlotReservationCategoryLengthRule: SlotReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SlotReservation) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SlotReservationTitleLengthRule: SlotReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SlotReservation) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a slot reservation.
    final class SlotReservationValidator {
        var rules: [any SlotReservationRule]

        init(rules: [any SlotReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: SlotReservation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SlotReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SlotReservation]) -> [String: [String]] {
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

    static func defaultSlotReservationValidator() -> SlotReservationValidator {
        return SlotReservationValidator(
            rules: [
                SlotReservationWindowDaysRangeRule(min: 1000, max: 86400),
                SlotReservationCategoryLengthRule(maxLength: 120),
                SlotReservationTitleLengthRule(maxLength: 1000),
            ]
        )
    }
}
