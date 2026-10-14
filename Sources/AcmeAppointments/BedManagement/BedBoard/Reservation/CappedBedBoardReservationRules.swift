import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a capped bed board reservation must pass. Check returns its problems, or none.
    protocol CappedBedBoardReservationRule {
        func check(_ item: CappedBedBoardReservation) -> [String]
    }

    final class CappedBedBoardReservationNameLengthRule: CappedBedBoardReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedBedBoardReservation) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedBedBoardReservationRefillsRangeRule: CappedBedBoardReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedBedBoardReservation) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedBedBoardReservationAllowedNameRule: CappedBedBoardReservationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedBedBoardReservation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is stale"]
            }
            return []
        }
    }

    final class CappedBedBoardReservationAttemptsRangeRule: CappedBedBoardReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedBedBoardReservation) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CappedBedBoardReservationRequiredCodeRule: CappedBedBoardReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedBedBoardReservation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a capped bed board reservation.
    final class CappedBedBoardReservationValidator {
        var rules: [any CappedBedBoardReservationRule]

        init(rules: [any CappedBedBoardReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedBedBoardReservation) -> [String] {
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

        func requireValid(_ item: CappedBedBoardReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedBedBoardReservation]) -> [String: [String]] {
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

    static func defaultCappedBedBoardReservationValidator() -> CappedBedBoardReservationValidator {
        return CappedBedBoardReservationValidator(
            rules: [
                CappedBedBoardReservationNameLengthRule(maxLength: 255),
                CappedBedBoardReservationRefillsRangeRule(min: 120, max: 1000),
                CappedBedBoardReservationAllowedNameRule(allowed: ["capped"]),
                CappedBedBoardReservationAttemptsRangeRule(min: 1000, max: 3600),
                CappedBedBoardReservationRequiredCodeRule(message: "capped bed board reservation needs this field"),
            ]
        )
    }
}
