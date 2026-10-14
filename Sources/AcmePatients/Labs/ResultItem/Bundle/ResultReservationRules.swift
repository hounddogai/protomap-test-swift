import AcmePlatform
import Foundation

extension Labs {
    /// A rule a result reservation must pass. Check returns its problems, or none.
    protocol ResultReservationRule {
        func check(_ item: ResultReservation) -> [String]
    }

    final class ResultReservationAmountRangeRule: ResultReservationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ResultReservation) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ResultReservationRequiredCodeRule: ResultReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ResultReservation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ResultReservationAllowedCodeRule: ResultReservationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ResultReservation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is too long"]
            }
            return []
        }
    }

    final class ResultReservationCodePrefixRule: ResultReservationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ResultReservation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ResultReservationCategoryLengthRule: ResultReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ResultReservation) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ResultReservationLabelLengthRule: ResultReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ResultReservation) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a result reservation.
    final class ResultReservationValidator {
        var rules: [any ResultReservationRule]

        init(rules: [any ResultReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: ResultReservation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ResultReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ResultReservation]) -> [String: [String]] {
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

    static func defaultResultReservationValidator() -> ResultReservationValidator {
        return ResultReservationValidator(
            rules: [
                ResultReservationAmountRangeRule(min: 4.5, max: 2563.2),
                ResultReservationRequiredCodeRule(message: "result reservation needs a value"),
                ResultReservationAllowedCodeRule(allowed: ["seasonal", "capped"]),
                ResultReservationCodePrefixRule(prefix: "REF"),
                ResultReservationCategoryLengthRule(maxLength: 120),
                ResultReservationLabelLengthRule(maxLength: 16),
            ]
        )
    }
}
