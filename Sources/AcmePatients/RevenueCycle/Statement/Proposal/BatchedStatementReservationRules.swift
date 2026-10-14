import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a batched statement reservation must pass. Check returns its problems, or none.
    protocol BatchedStatementReservationRule {
        func check(_ item: BatchedStatementReservation) -> [String]
    }

    final class BatchedStatementReservationRequiredCodeRule: BatchedStatementReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedStatementReservation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedStatementReservationCodeLengthRule: BatchedStatementReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedStatementReservation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedStatementReservationPayerLengthRule: BatchedStatementReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedStatementReservation) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched statement reservation.
    final class BatchedStatementReservationValidator {
        var rules: [any BatchedStatementReservationRule]

        init(rules: [any BatchedStatementReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedStatementReservation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedStatementReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedStatementReservation]) -> [String: [String]] {
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

    static func defaultBatchedStatementReservationValidator() -> BatchedStatementReservationValidator {
        return BatchedStatementReservationValidator(
            rules: [
                BatchedStatementReservationRequiredCodeRule(message: "batched statement reservation needs this field"),
                BatchedStatementReservationCodeLengthRule(maxLength: 64),
                BatchedStatementReservationPayerLengthRule(maxLength: 80),
            ]
        )
    }
}
