import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a primary inventory plan must pass. Check returns its problems, or none.
    protocol PrimaryInventoryPlanRule {
        func check(_ item: PrimaryInventoryPlan) -> [String]
    }

    final class PrimaryInventoryPlanWeightRangeRule: PrimaryInventoryPlanRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryInventoryPlan) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PrimaryInventoryPlanVersionRangeRule: PrimaryInventoryPlanRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryInventoryPlan) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PrimaryInventoryPlanTitleLengthRule: PrimaryInventoryPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryInventoryPlan) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryInventoryPlanCodePrefixRule: PrimaryInventoryPlanRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryInventoryPlan) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PrimaryInventoryPlanRequiredCodeRule: PrimaryInventoryPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryInventoryPlan) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryInventoryPlanRequiredPhoneRule: PrimaryInventoryPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryInventoryPlan) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a primary inventory plan.
    final class PrimaryInventoryPlanValidator {
        var rules: [any PrimaryInventoryPlanRule]

        init(rules: [any PrimaryInventoryPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryInventoryPlan) -> [String] {
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

        func requireValid(_ item: PrimaryInventoryPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryInventoryPlan]) -> [String: [String]] {
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

    static func defaultPrimaryInventoryPlanValidator() -> PrimaryInventoryPlanValidator {
        return PrimaryInventoryPlanValidator(
            rules: [
                PrimaryInventoryPlanWeightRangeRule(min: 6.6, max: 920.9),
                PrimaryInventoryPlanVersionRangeRule(min: 32, max: 255),
                PrimaryInventoryPlanTitleLengthRule(maxLength: 3600),
                PrimaryInventoryPlanCodePrefixRule(prefix: "X"),
                PrimaryInventoryPlanRequiredCodeRule(message: "primary inventory plan needs an entry"),
                PrimaryInventoryPlanRequiredPhoneRule(message: "primary inventory plan needs this field"),
            ]
        )
    }
}
