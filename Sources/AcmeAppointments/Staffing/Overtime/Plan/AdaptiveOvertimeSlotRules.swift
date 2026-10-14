import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a adaptive overtime slot must pass. Check returns its problems, or none.
    protocol AdaptiveOvertimeSlotRule {
        func check(_ item: AdaptiveOvertimeSlot) -> [String]
    }

    final class AdaptiveOvertimeSlotCurrencyLengthRule: AdaptiveOvertimeSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveOvertimeSlot) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveOvertimeSlotNameLengthRule: AdaptiveOvertimeSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveOvertimeSlot) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveOvertimeSlotAllowedCategoryRule: AdaptiveOvertimeSlotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveOvertimeSlot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.category)) {
                return ["category \(item.category) is inconsistent"]
            }
            return []
        }
    }

    final class AdaptiveOvertimeSlotRequiredCategoryRule: AdaptiveOvertimeSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveOvertimeSlot) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive overtime slot.
    final class AdaptiveOvertimeSlotValidator {
        var rules: [any AdaptiveOvertimeSlotRule]

        init(rules: [any AdaptiveOvertimeSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveOvertimeSlot) -> [String] {
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

        func requireValid(_ item: AdaptiveOvertimeSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveOvertimeSlot]) -> [String: [String]] {
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

    static func defaultAdaptiveOvertimeSlotValidator() -> AdaptiveOvertimeSlotValidator {
        return AdaptiveOvertimeSlotValidator(
            rules: [
                AdaptiveOvertimeSlotCurrencyLengthRule(maxLength: 1000),
                AdaptiveOvertimeSlotNameLengthRule(maxLength: 86400),
                AdaptiveOvertimeSlotAllowedCategoryRule(allowed: ["lenient"]),
                AdaptiveOvertimeSlotRequiredCategoryRule(message: "adaptive overtime slot needs an entry"),
            ]
        )
    }
}
