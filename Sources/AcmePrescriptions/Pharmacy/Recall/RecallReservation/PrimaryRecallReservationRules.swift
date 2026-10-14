import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a primary recall reservation must pass. Check returns its problems, or none.
    protocol PrimaryRecallReservationRule {
        func check(_ item: PrimaryRecallReservation) -> [String]
    }

    final class PrimaryRecallReservationRequiredLabelRule: PrimaryRecallReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryRecallReservation) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryRecallReservationCodePrefixRule: PrimaryRecallReservationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryRecallReservation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PrimaryRecallReservationRequiredCodeRule: PrimaryRecallReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryRecallReservation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryRecallReservationAllowedLabelRule: PrimaryRecallReservationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryRecallReservation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is duplicated"]
            }
            return []
        }
    }

    final class PrimaryRecallReservationCostRangeRule: PrimaryRecallReservationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryRecallReservation) -> [String] {
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

    /// Runs every rule of a primary recall reservation.
    final class PrimaryRecallReservationValidator {
        var rules: [any PrimaryRecallReservationRule]

        init(rules: [any PrimaryRecallReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryRecallReservation) -> [String] {
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

        func requireValid(_ item: PrimaryRecallReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryRecallReservation]) -> [String: [String]] {
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

    static func defaultPrimaryRecallReservationValidator() -> PrimaryRecallReservationValidator {
        return PrimaryRecallReservationValidator(
            rules: [
                PrimaryRecallReservationRequiredLabelRule(message: "primary recall reservation needs a value"),
                PrimaryRecallReservationCodePrefixRule(prefix: "Q"),
                PrimaryRecallReservationRequiredCodeRule(message: "primary recall reservation needs an entry"),
                PrimaryRecallReservationAllowedLabelRule(allowed: ["lenient"]),
                PrimaryRecallReservationCostRangeRule(min: 1.3, max: 3680.3),
            ]
        )
    }
}
