import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a float pool window must pass. Check returns its problems, or none.
    protocol FloatPoolWindowRule {
        func check(_ item: FloatPoolWindow) -> [String]
    }

    final class FloatPoolWindowCodeLengthRule: FloatPoolWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FloatPoolWindow) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FloatPoolWindowBudgetRangeRule: FloatPoolWindowRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FloatPoolWindow) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FloatPoolWindowRequiredDiagnosisCodeRule: FloatPoolWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FloatPoolWindow) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FloatPoolWindowRequiredContactEmailRule: FloatPoolWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FloatPoolWindow) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FloatPoolWindowLabelLengthRule: FloatPoolWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FloatPoolWindow) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a float pool window.
    final class FloatPoolWindowValidator {
        var rules: [any FloatPoolWindowRule]

        init(rules: [any FloatPoolWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: FloatPoolWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FloatPoolWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FloatPoolWindow]) -> [String: [String]] {
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

    static func defaultFloatPoolWindowValidator() -> FloatPoolWindowValidator {
        return FloatPoolWindowValidator(
            rules: [
                FloatPoolWindowCodeLengthRule(maxLength: 64),
                FloatPoolWindowBudgetRangeRule(min: 8.1, max: 4210.1),
                FloatPoolWindowRequiredDiagnosisCodeRule(message: "float pool window needs this field"),
                FloatPoolWindowRequiredContactEmailRule(message: "float pool window needs this field"),
                FloatPoolWindowLabelLengthRule(maxLength: 3600),
            ]
        )
    }
}
