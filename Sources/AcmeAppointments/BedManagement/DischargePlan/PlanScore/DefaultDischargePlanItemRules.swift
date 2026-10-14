import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a default discharge plan item must pass. Check returns its problems, or none.
    protocol DefaultDischargePlanItemRule {
        func check(_ item: DefaultDischargePlanItem) -> [String]
    }

    final class DefaultDischargePlanItemNameLengthRule: DefaultDischargePlanItemRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultDischargePlanItem) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultDischargePlanItemCodePrefixRule: DefaultDischargePlanItemRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultDischargePlanItem) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DefaultDischargePlanItemRatioRangeRule: DefaultDischargePlanItemRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultDischargePlanItem) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultDischargePlanItemRetriesRangeRule: DefaultDischargePlanItemRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultDischargePlanItem) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DefaultDischargePlanItemQuantityRangeRule: DefaultDischargePlanItemRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultDischargePlanItem) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DefaultDischargePlanItemRequiredCodeRule: DefaultDischargePlanItemRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultDischargePlanItem) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a default discharge plan item.
    final class DefaultDischargePlanItemValidator {
        var rules: [any DefaultDischargePlanItemRule]

        init(rules: [any DefaultDischargePlanItemRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultDischargePlanItem) -> [String] {
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

        func requireValid(_ item: DefaultDischargePlanItem) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultDischargePlanItem]) -> [String: [String]] {
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

    static func defaultDefaultDischargePlanItemValidator() -> DefaultDischargePlanItemValidator {
        return DefaultDischargePlanItemValidator(
            rules: [
                DefaultDischargePlanItemNameLengthRule(maxLength: 80),
                DefaultDischargePlanItemCodePrefixRule(prefix: "Q"),
                DefaultDischargePlanItemRatioRangeRule(min: 9.4, max: 2815.9),
                DefaultDischargePlanItemRetriesRangeRule(min: 32, max: 32),
                DefaultDischargePlanItemQuantityRangeRule(min: 16, max: 120),
                DefaultDischargePlanItemRequiredCodeRule(message: "default discharge plan item needs a value"),
            ]
        )
    }
}
