import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a priority reservation must pass. Check returns its problems, or none.
    protocol PriorityReservationRule {
        func check(_ item: PriorityReservation) -> [String]
    }

    final class PriorityReservationMaximumRangeRule: PriorityReservationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PriorityReservation) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PriorityReservationVisibleGuardRule: PriorityReservationRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: PriorityReservation) -> [String] {
            if item.visible && (item.ceiling > limit) {
                return ["ceiling \(item.ceiling) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class PriorityReservationRequiredNameRule: PriorityReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PriorityReservation) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a priority reservation.
    final class PriorityReservationValidator {
        var rules: [any PriorityReservationRule]

        init(rules: [any PriorityReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: PriorityReservation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PriorityReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PriorityReservation]) -> [String: [String]] {
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

    static func defaultPriorityReservationValidator() -> PriorityReservationValidator {
        return PriorityReservationValidator(
            rules: [
                PriorityReservationMaximumRangeRule(min: 8.9, max: 2118.1),
                PriorityReservationVisibleGuardRule(limit: 1.3),
                PriorityReservationRequiredNameRule(message: "priority reservation needs a value"),
            ]
        )
    }
}
