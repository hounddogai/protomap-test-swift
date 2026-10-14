import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a statement exception must pass. Check returns its problems, or none.
    protocol StatementExceptionRule {
        func check(_ item: StatementException) -> [String]
    }

    final class StatementExceptionScoreRangeRule: StatementExceptionRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StatementException) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StatementExceptionCodeLengthRule: StatementExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StatementException) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StatementExceptionExpiresAtRangeRule: StatementExceptionRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StatementException) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StatementExceptionRequiredPatientRefRule: StatementExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StatementException) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StatementExceptionCodePrefixRule: StatementExceptionRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StatementException) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a statement exception.
    final class StatementExceptionValidator {
        var rules: [any StatementExceptionRule]

        init(rules: [any StatementExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: StatementException) -> [String] {
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

        func requireValid(_ item: StatementException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StatementException]) -> [String: [String]] {
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

    static func defaultStatementExceptionValidator() -> StatementExceptionValidator {
        return StatementExceptionValidator(
            rules: [
                StatementExceptionScoreRangeRule(min: 7.0, max: 2071.5),
                StatementExceptionCodeLengthRule(maxLength: 64),
                StatementExceptionExpiresAtRangeRule(min: 120, max: 3600),
                StatementExceptionRequiredPatientRefRule(message: "statement exception needs a value"),
                StatementExceptionCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
