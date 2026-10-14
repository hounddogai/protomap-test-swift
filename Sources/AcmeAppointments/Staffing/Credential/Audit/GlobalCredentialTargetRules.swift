import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a global credential target must pass. Check returns its problems, or none.
    protocol GlobalCredentialTargetRule {
        func check(_ item: GlobalCredentialTarget) -> [String]
    }

    final class GlobalCredentialTargetBudgetRangeRule: GlobalCredentialTargetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalCredentialTarget) -> [String] {
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

    final class GlobalCredentialTargetRequiredCurrencyRule: GlobalCredentialTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalCredentialTarget) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalCredentialTargetUpdatedAtRangeRule: GlobalCredentialTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalCredentialTarget) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalCredentialTargetDiagnosisCodeLengthRule: GlobalCredentialTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalCredentialTarget) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global credential target.
    final class GlobalCredentialTargetValidator {
        var rules: [any GlobalCredentialTargetRule]

        init(rules: [any GlobalCredentialTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalCredentialTarget) -> [String] {
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

        func requireValid(_ item: GlobalCredentialTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalCredentialTarget]) -> [String: [String]] {
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

    static func defaultGlobalCredentialTargetValidator() -> GlobalCredentialTargetValidator {
        return GlobalCredentialTargetValidator(
            rules: [
                GlobalCredentialTargetBudgetRangeRule(min: 7.5, max: 2289.3),
                GlobalCredentialTargetRequiredCurrencyRule(message: "global credential target needs this field"),
                GlobalCredentialTargetUpdatedAtRangeRule(min: 80, max: 1000),
                GlobalCredentialTargetDiagnosisCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
