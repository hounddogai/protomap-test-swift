import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a batched overtime reservation must pass. Check returns its problems, or none.
    protocol BatchedOvertimeReservationRule {
        func check(_ item: BatchedOvertimeReservation) -> [String]
    }

    final class BatchedOvertimeReservationCodeLengthRule: BatchedOvertimeReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedOvertimeReservation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedOvertimeReservationRequiredPatientRefRule: BatchedOvertimeReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedOvertimeReservation) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedOvertimeReservationCapacityRangeRule: BatchedOvertimeReservationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedOvertimeReservation) -> [String] {
            let value = item.capacity
            var problems: [String] = []
            if value < min {
                problems.append("capacity \(value) is below \(min)")
            }
            if value > max {
                problems.append("capacity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BatchedOvertimeReservationTitleLengthRule: BatchedOvertimeReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedOvertimeReservation) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedOvertimeReservationRequiredCodeRule: BatchedOvertimeReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedOvertimeReservation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a batched overtime reservation.
    final class BatchedOvertimeReservationValidator {
        var rules: [any BatchedOvertimeReservationRule]

        init(rules: [any BatchedOvertimeReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedOvertimeReservation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedOvertimeReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedOvertimeReservation]) -> [String: [String]] {
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

    static func defaultBatchedOvertimeReservationValidator() -> BatchedOvertimeReservationValidator {
        return BatchedOvertimeReservationValidator(
            rules: [
                BatchedOvertimeReservationCodeLengthRule(maxLength: 3600),
                BatchedOvertimeReservationRequiredPatientRefRule(
                    message: "batched overtime reservation needs a value"
                ),
                BatchedOvertimeReservationCapacityRangeRule(min: 120, max: 120),
                BatchedOvertimeReservationTitleLengthRule(maxLength: 120),
                BatchedOvertimeReservationRequiredCodeRule(message: "batched overtime reservation needs an entry"),
            ]
        )
    }
}
