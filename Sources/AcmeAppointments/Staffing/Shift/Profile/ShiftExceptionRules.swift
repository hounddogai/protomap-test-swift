import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a shift exception must pass. Check returns its problems, or none.
    protocol ShiftExceptionRule {
        func check(_ item: ShiftException) -> [String]
    }

    final class ShiftExceptionSummaryLengthRule: ShiftExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ShiftException) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ShiftExceptionCopayRangeRule: ShiftExceptionRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ShiftException) -> [String] {
            let value = item.copay
            var problems: [String] = []
            if value < min {
                problems.append("copay \(value) is below \(min)")
            }
            if value > max {
                problems.append("copay \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ShiftExceptionRequiredSummaryRule: ShiftExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ShiftException) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ShiftExceptionDosageMgRangeRule: ShiftExceptionRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ShiftException) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ShiftExceptionRequiredSourceRule: ShiftExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ShiftException) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ShiftExceptionRequiredCodeRule: ShiftExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ShiftException) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a shift exception.
    final class ShiftExceptionValidator {
        var rules: [any ShiftExceptionRule]

        init(rules: [any ShiftExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: ShiftException) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ShiftException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ShiftException]) -> [String: [String]] {
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

    static func defaultShiftExceptionValidator() -> ShiftExceptionValidator {
        return ShiftExceptionValidator(
            rules: [
                ShiftExceptionSummaryLengthRule(maxLength: 255),
                ShiftExceptionCopayRangeRule(min: 3.1, max: 1001.9),
                ShiftExceptionRequiredSummaryRule(message: "shift exception needs a value"),
                ShiftExceptionDosageMgRangeRule(min: 8.5, max: 3240.4),
                ShiftExceptionRequiredSourceRule(message: "shift exception needs an entry"),
                ShiftExceptionRequiredCodeRule(message: "shift exception needs this field"),
            ]
        )
    }
}
