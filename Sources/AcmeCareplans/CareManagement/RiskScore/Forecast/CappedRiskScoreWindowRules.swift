import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a capped risk score window must pass. Check returns its problems, or none.
    protocol CappedRiskScoreWindowRule {
        func check(_ item: CappedRiskScoreWindow) -> [String]
    }

    final class CappedRiskScoreWindowCodeLengthRule: CappedRiskScoreWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedRiskScoreWindow) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedRiskScoreWindowDescriptionLengthRule: CappedRiskScoreWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedRiskScoreWindow) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedRiskScoreWindowRequiredCodeRule: CappedRiskScoreWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedRiskScoreWindow) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedRiskScoreWindowCurrencyLengthRule: CappedRiskScoreWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedRiskScoreWindow) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedRiskScoreWindowRatioRangeRule: CappedRiskScoreWindowRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedRiskScoreWindow) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedRiskScoreWindowBudgetRangeRule: CappedRiskScoreWindowRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedRiskScoreWindow) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped risk score window.
    final class CappedRiskScoreWindowValidator {
        var rules: [any CappedRiskScoreWindowRule]

        init(rules: [any CappedRiskScoreWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedRiskScoreWindow) -> [String] {
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

        func requireValid(_ item: CappedRiskScoreWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedRiskScoreWindow]) -> [String: [String]] {
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

    static func defaultCappedRiskScoreWindowValidator() -> CappedRiskScoreWindowValidator {
        return CappedRiskScoreWindowValidator(
            rules: [
                CappedRiskScoreWindowCodeLengthRule(maxLength: 255),
                CappedRiskScoreWindowDescriptionLengthRule(maxLength: 255),
                CappedRiskScoreWindowRequiredCodeRule(message: "capped risk score window needs a value"),
                CappedRiskScoreWindowCurrencyLengthRule(maxLength: 32),
                CappedRiskScoreWindowRatioRangeRule(min: 8.3, max: 2244.0),
                CappedRiskScoreWindowBudgetRangeRule(min: 2.3, max: 305.8),
            ]
        )
    }
}
