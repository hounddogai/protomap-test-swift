import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a remittance override must pass. Check returns its problems, or none.
    protocol RemittanceOverrideRule {
        func check(_ item: RemittanceOverride) -> [String]
    }

    final class RemittanceOverrideRequiredLabelRule: RemittanceOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RemittanceOverride) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RemittanceOverrideCodeLengthRule: RemittanceOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RemittanceOverride) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RemittanceOverrideMinimumRangeRule: RemittanceOverrideRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RemittanceOverride) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RemittanceOverrideQuantityRangeRule: RemittanceOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RemittanceOverride) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RemittanceOverrideRequiredCodeRule: RemittanceOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RemittanceOverride) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a remittance override.
    final class RemittanceOverrideValidator {
        var rules: [any RemittanceOverrideRule]

        init(rules: [any RemittanceOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: RemittanceOverride) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RemittanceOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RemittanceOverride]) -> [String: [String]] {
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

    static func defaultRemittanceOverrideValidator() -> RemittanceOverrideValidator {
        return RemittanceOverrideValidator(
            rules: [
                RemittanceOverrideRequiredLabelRule(message: "remittance override needs an entry"),
                RemittanceOverrideCodeLengthRule(maxLength: 32),
                RemittanceOverrideMinimumRangeRule(min: 7.3, max: 2598.9),
                RemittanceOverrideQuantityRangeRule(min: 255, max: 255),
                RemittanceOverrideRequiredCodeRule(message: "remittance override needs a value"),
            ]
        )
    }
}
