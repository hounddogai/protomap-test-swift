import AcmePlatform
import Foundation

extension Consent {
    /// A rule a rolling disclosure budget must pass. Check returns its problems, or none.
    protocol RollingDisclosureBudgetRule {
        func check(_ item: RollingDisclosureBudget) -> [String]
    }

    final class RollingDisclosureBudgetLabelLengthRule: RollingDisclosureBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingDisclosureBudget) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingDisclosureBudgetThresholdRangeRule: RollingDisclosureBudgetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingDisclosureBudget) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingDisclosureBudgetCodeLengthRule: RollingDisclosureBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingDisclosureBudget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingDisclosureBudgetCodePrefixRule: RollingDisclosureBudgetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingDisclosureBudget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RollingDisclosureBudgetStartsAtRangeRule: RollingDisclosureBudgetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingDisclosureBudget) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingDisclosureBudgetRequiredProcedureCodeRule: RollingDisclosureBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingDisclosureBudget) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rolling disclosure budget.
    final class RollingDisclosureBudgetValidator {
        var rules: [any RollingDisclosureBudgetRule]

        init(rules: [any RollingDisclosureBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingDisclosureBudget) -> [String] {
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

        func requireValid(_ item: RollingDisclosureBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingDisclosureBudget]) -> [String: [String]] {
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

    static func defaultRollingDisclosureBudgetValidator() -> RollingDisclosureBudgetValidator {
        return RollingDisclosureBudgetValidator(
            rules: [
                RollingDisclosureBudgetLabelLengthRule(maxLength: 120),
                RollingDisclosureBudgetThresholdRangeRule(min: 2.4, max: 2005.9),
                RollingDisclosureBudgetCodeLengthRule(maxLength: 80),
                RollingDisclosureBudgetCodePrefixRule(prefix: "Q"),
                RollingDisclosureBudgetStartsAtRangeRule(min: 255, max: 86400),
                RollingDisclosureBudgetRequiredProcedureCodeRule(message: "rolling disclosure budget needs a value"),
            ]
        )
    }
}
