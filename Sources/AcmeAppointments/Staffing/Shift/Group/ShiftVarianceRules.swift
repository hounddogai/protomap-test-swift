import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a shift variance must pass. Check returns its problems, or none.
    protocol ShiftVarianceRule {
        func check(_ item: ShiftVariance) -> [String]
    }

    final class ShiftVarianceCodeLengthRule: ShiftVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ShiftVariance) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ShiftVarianceTitleLengthRule: ShiftVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ShiftVariance) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ShiftVarianceReviewerLengthRule: ShiftVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ShiftVariance) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ShiftVarianceRequiredTitleRule: ShiftVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ShiftVariance) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a shift variance.
    final class ShiftVarianceValidator {
        var rules: [any ShiftVarianceRule]

        init(rules: [any ShiftVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: ShiftVariance) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ShiftVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ShiftVariance]) -> [String: [String]] {
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

    static func defaultShiftVarianceValidator() -> ShiftVarianceValidator {
        return ShiftVarianceValidator(
            rules: [
                ShiftVarianceCodeLengthRule(maxLength: 255),
                ShiftVarianceTitleLengthRule(maxLength: 1000),
                ShiftVarianceReviewerLengthRule(maxLength: 3600),
                ShiftVarianceRequiredTitleRule(message: "shift variance needs an entry"),
            ]
        )
    }
}
