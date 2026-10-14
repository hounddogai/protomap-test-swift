import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a formulary rollup must pass. Check returns its problems, or none.
    protocol FormularyRollupRule {
        func check(_ item: FormularyRollup) -> [String]
    }

    final class FormularyRollupTitleLengthRule: FormularyRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FormularyRollup) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FormularyRollupGraceDaysRangeRule: FormularyRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FormularyRollup) -> [String] {
            let value = item.graceDays
            var problems: [String] = []
            if value < min {
                problems.append("grace days \(value) is below \(min)")
            }
            if value > max {
                problems.append("grace days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FormularyRollupCodeLengthRule: FormularyRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FormularyRollup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a formulary rollup.
    final class FormularyRollupValidator {
        var rules: [any FormularyRollupRule]

        init(rules: [any FormularyRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: FormularyRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FormularyRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FormularyRollup]) -> [String: [String]] {
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

    static func defaultFormularyRollupValidator() -> FormularyRollupValidator {
        return FormularyRollupValidator(
            rules: [
                FormularyRollupTitleLengthRule(maxLength: 64),
                FormularyRollupGraceDaysRangeRule(min: 32, max: 64),
                FormularyRollupCodeLengthRule(maxLength: 255),
            ]
        )
    }
}
