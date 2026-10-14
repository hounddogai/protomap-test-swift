import AcmePlatform
import Foundation

extension Labs {
    /// A rule a rolling accession reservation must pass. Check returns its problems, or none.
    protocol RollingAccessionReservationRule {
        func check(_ item: RollingAccessionReservation) -> [String]
    }

    final class RollingAccessionReservationRequiredUnitRule: RollingAccessionReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingAccessionReservation) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingAccessionReservationCodePrefixRule: RollingAccessionReservationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingAccessionReservation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RollingAccessionReservationUnitLengthRule: RollingAccessionReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingAccessionReservation) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingAccessionReservationRequiredCodeRule: RollingAccessionReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingAccessionReservation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rolling accession reservation.
    final class RollingAccessionReservationValidator {
        var rules: [any RollingAccessionReservationRule]

        init(rules: [any RollingAccessionReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingAccessionReservation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingAccessionReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingAccessionReservation]) -> [String: [String]] {
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

    static func defaultRollingAccessionReservationValidator() -> RollingAccessionReservationValidator {
        return RollingAccessionReservationValidator(
            rules: [
                RollingAccessionReservationRequiredUnitRule(message: "rolling accession reservation needs a value"),
                RollingAccessionReservationCodePrefixRule(prefix: "REF"),
                RollingAccessionReservationUnitLengthRule(maxLength: 120),
                RollingAccessionReservationRequiredCodeRule(message: "rolling accession reservation needs an entry"),
            ]
        )
    }
}
