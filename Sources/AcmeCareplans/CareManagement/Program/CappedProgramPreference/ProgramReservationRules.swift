import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a program reservation must pass. Check returns its problems, or none.
    protocol ProgramReservationRule {
        func check(_ item: ProgramReservation) -> [String]
    }

    final class ProgramReservationSegmentLengthRule: ProgramReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProgramReservation) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProgramReservationRequiredCodeRule: ProgramReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProgramReservation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProgramReservationRequiredSegmentRule: ProgramReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProgramReservation) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProgramReservationAllowedSegmentRule: ProgramReservationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ProgramReservation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.segment)) {
                return ["segment \(item.segment) is unknown"]
            }
            return []
        }
    }

    final class ProgramReservationRequiredProcedureCodeRule: ProgramReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProgramReservation) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProgramReservationCodeLengthRule: ProgramReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProgramReservation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a program reservation.
    final class ProgramReservationValidator {
        var rules: [any ProgramReservationRule]

        init(rules: [any ProgramReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: ProgramReservation) -> [String] {
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

        func requireValid(_ item: ProgramReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProgramReservation]) -> [String: [String]] {
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

    static func defaultProgramReservationValidator() -> ProgramReservationValidator {
        return ProgramReservationValidator(
            rules: [
                ProgramReservationSegmentLengthRule(maxLength: 64),
                ProgramReservationRequiredCodeRule(message: "program reservation needs this field"),
                ProgramReservationRequiredSegmentRule(message: "program reservation needs this field"),
                ProgramReservationAllowedSegmentRule(allowed: ["tiered"]),
                ProgramReservationRequiredProcedureCodeRule(message: "program reservation needs a value"),
                ProgramReservationCodeLengthRule(maxLength: 1000),
            ]
        )
    }
}
