import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a adaptive priority group must pass. Check returns its problems, or none.
    protocol AdaptivePriorityGroupRule {
        func check(_ item: AdaptivePriorityGroup) -> [String]
    }

    final class AdaptivePriorityGroupRequiredUnitRule: AdaptivePriorityGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptivePriorityGroup) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptivePriorityGroupDiscountRangeRule: AdaptivePriorityGroupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptivePriorityGroup) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptivePriorityGroupLabelLengthRule: AdaptivePriorityGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptivePriorityGroup) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptivePriorityGroupRequiredCurrencyRule: AdaptivePriorityGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptivePriorityGroup) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptivePriorityGroupUnitLengthRule: AdaptivePriorityGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptivePriorityGroup) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptivePriorityGroupAllowedCurrencyRule: AdaptivePriorityGroupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptivePriorityGroup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.currency)) {
                return ["currency \(item.currency) is unknown"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive priority group.
    final class AdaptivePriorityGroupValidator {
        var rules: [any AdaptivePriorityGroupRule]

        init(rules: [any AdaptivePriorityGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptivePriorityGroup) -> [String] {
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

        func requireValid(_ item: AdaptivePriorityGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptivePriorityGroup]) -> [String: [String]] {
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

    static func defaultAdaptivePriorityGroupValidator() -> AdaptivePriorityGroupValidator {
        return AdaptivePriorityGroupValidator(
            rules: [
                AdaptivePriorityGroupRequiredUnitRule(message: "adaptive priority group needs this field"),
                AdaptivePriorityGroupDiscountRangeRule(min: 7.0, max: 611.8),
                AdaptivePriorityGroupLabelLengthRule(maxLength: 1000),
                AdaptivePriorityGroupRequiredCurrencyRule(message: "adaptive priority group needs this field"),
                AdaptivePriorityGroupUnitLengthRule(maxLength: 3600),
                AdaptivePriorityGroupAllowedCurrencyRule(allowed: ["adaptive"]),
            ]
        )
    }
}
