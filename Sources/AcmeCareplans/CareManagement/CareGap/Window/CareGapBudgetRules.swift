import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a care gap budget must pass. Check returns its problems, or none.
    protocol CareGapBudgetRule {
        func check(_ item: CareGapBudget) -> [String]
    }

    final class CareGapBudgetPhoneLengthRule: CareGapBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareGapBudget) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareGapBudgetAllowedSummaryRule: CareGapBudgetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CareGapBudget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.summary)) {
                return ["summary \(item.summary) is not allowed"]
            }
            return []
        }
    }

    final class CareGapBudgetRequiredNameRule: CareGapBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareGapBudget) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareGapBudgetRequiredCodeRule: CareGapBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareGapBudget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareGapBudgetRequiredPhoneRule: CareGapBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareGapBudget) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareGapBudgetMaximumRangeRule: CareGapBudgetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareGapBudget) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a care gap budget.
    final class CareGapBudgetValidator {
        var rules: [any CareGapBudgetRule]

        init(rules: [any CareGapBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: CareGapBudget) -> [String] {
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

        func requireValid(_ item: CareGapBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareGapBudget]) -> [String: [String]] {
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

    static func defaultCareGapBudgetValidator() -> CareGapBudgetValidator {
        return CareGapBudgetValidator(
            rules: [
                CareGapBudgetPhoneLengthRule(maxLength: 80),
                CareGapBudgetAllowedSummaryRule(allowed: []),
                CareGapBudgetRequiredNameRule(message: "care gap budget needs this field"),
                CareGapBudgetRequiredCodeRule(message: "care gap budget needs a value"),
                CareGapBudgetRequiredPhoneRule(message: "care gap budget needs this field"),
                CareGapBudgetMaximumRangeRule(min: 9.0, max: 1928.8),
            ]
        )
    }
}
