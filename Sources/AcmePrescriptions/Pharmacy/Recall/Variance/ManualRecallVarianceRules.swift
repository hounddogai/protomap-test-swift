import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a manual recall variance must pass. Check returns its problems, or none.
    protocol ManualRecallVarianceRule {
        func check(_ item: ManualRecallVariance) -> [String]
    }

    final class ManualRecallVarianceEndsAtRangeRule: ManualRecallVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualRecallVariance) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ManualRecallVarianceBudgetRangeRule: ManualRecallVarianceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualRecallVariance) -> [String] {
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

    final class ManualRecallVarianceCodePrefixRule: ManualRecallVarianceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualRecallVariance) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ManualRecallVarianceCodeLengthRule: ManualRecallVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualRecallVariance) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualRecallVarianceRequiredCurrencyRule: ManualRecallVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualRecallVariance) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a manual recall variance.
    final class ManualRecallVarianceValidator {
        var rules: [any ManualRecallVarianceRule]

        init(rules: [any ManualRecallVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualRecallVariance) -> [String] {
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

        func requireValid(_ item: ManualRecallVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualRecallVariance]) -> [String: [String]] {
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

    static func defaultManualRecallVarianceValidator() -> ManualRecallVarianceValidator {
        return ManualRecallVarianceValidator(
            rules: [
                ManualRecallVarianceEndsAtRangeRule(min: 32, max: 64),
                ManualRecallVarianceBudgetRangeRule(min: 5.1, max: 603.5),
                ManualRecallVarianceCodePrefixRule(prefix: "X"),
                ManualRecallVarianceCodeLengthRule(maxLength: 86400),
                ManualRecallVarianceRequiredCurrencyRule(message: "manual recall variance needs this field"),
            ]
        )
    }
}
