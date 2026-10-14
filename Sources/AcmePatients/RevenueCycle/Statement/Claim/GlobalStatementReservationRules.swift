import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a global statement reservation must pass. Check returns its problems, or none.
    protocol GlobalStatementReservationRule {
        func check(_ item: GlobalStatementReservation) -> [String]
    }

    final class GlobalStatementReservationCodePrefixRule: GlobalStatementReservationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalStatementReservation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GlobalStatementReservationRequiredLabelRule: GlobalStatementReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalStatementReservation) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalStatementReservationLimitRangeRule: GlobalStatementReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalStatementReservation) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a global statement reservation.
    final class GlobalStatementReservationValidator {
        var rules: [any GlobalStatementReservationRule]

        init(rules: [any GlobalStatementReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalStatementReservation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalStatementReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalStatementReservation]) -> [String: [String]] {
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

    static func defaultGlobalStatementReservationValidator() -> GlobalStatementReservationValidator {
        return GlobalStatementReservationValidator(
            rules: [
                GlobalStatementReservationCodePrefixRule(prefix: "OPS"),
                GlobalStatementReservationRequiredLabelRule(message: "global statement reservation needs an entry"),
                GlobalStatementReservationLimitRangeRule(min: 32, max: 1000),
            ]
        )
    }
}
