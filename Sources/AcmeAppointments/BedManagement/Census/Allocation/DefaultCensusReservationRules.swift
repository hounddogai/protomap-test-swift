import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a default census reservation must pass. Check returns its problems, or none.
    protocol DefaultCensusReservationRule {
        func check(_ item: DefaultCensusReservation) -> [String]
    }

    final class DefaultCensusReservationAllowedProcedureCodeRule: DefaultCensusReservationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DefaultCensusReservation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.procedureCode)) {
                return ["procedure code \(item.procedureCode) is inconsistent"]
            }
            return []
        }
    }

    final class DefaultCensusReservationRequiredCodeRule: DefaultCensusReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultCensusReservation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultCensusReservationSegmentLengthRule: DefaultCensusReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultCensusReservation) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultCensusReservationCodeLengthRule: DefaultCensusReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultCensusReservation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultCensusReservationStartsAtRangeRule: DefaultCensusReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultCensusReservation) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a default census reservation.
    final class DefaultCensusReservationValidator {
        var rules: [any DefaultCensusReservationRule]

        init(rules: [any DefaultCensusReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultCensusReservation) -> [String] {
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

        func requireValid(_ item: DefaultCensusReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultCensusReservation]) -> [String: [String]] {
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

    static func defaultDefaultCensusReservationValidator() -> DefaultCensusReservationValidator {
        return DefaultCensusReservationValidator(
            rules: [
                DefaultCensusReservationAllowedProcedureCodeRule(allowed: ["primary", "regional"]),
                DefaultCensusReservationRequiredCodeRule(message: "default census reservation needs this field"),
                DefaultCensusReservationSegmentLengthRule(maxLength: 86400),
                DefaultCensusReservationCodeLengthRule(maxLength: 32),
                DefaultCensusReservationStartsAtRangeRule(min: 80, max: 86400),
            ]
        )
    }
}
