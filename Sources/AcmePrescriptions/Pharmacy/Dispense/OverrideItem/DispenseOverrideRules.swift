import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a dispense override must pass. Check returns its problems, or none.
    protocol DispenseOverrideRule {
        func check(_ item: DispenseOverride) -> [String]
    }

    final class DispenseOverrideRequiredExternalRefRule: DispenseOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DispenseOverride) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DispenseOverrideRequiredCodeRule: DispenseOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DispenseOverride) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DispenseOverrideDiscountRangeRule: DispenseOverrideRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DispenseOverride) -> [String] {
            let value = item.discount
            var problems: [String] = []
            if value < min {
                problems.append("discount \(value) is below \(min)")
            }
            if value > max {
                problems.append("discount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DispenseOverrideAllowedExternalRefRule: DispenseOverrideRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DispenseOverride) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.externalRef)) {
                return ["external ref \(item.externalRef) is expired"]
            }
            return []
        }
    }

    final class DispenseOverrideLabelLengthRule: DispenseOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DispenseOverride) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a dispense override.
    final class DispenseOverrideValidator {
        var rules: [any DispenseOverrideRule]

        init(rules: [any DispenseOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: DispenseOverride) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DispenseOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DispenseOverride]) -> [String: [String]] {
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

    static func defaultDispenseOverrideValidator() -> DispenseOverrideValidator {
        return DispenseOverrideValidator(
            rules: [
                DispenseOverrideRequiredExternalRefRule(message: "dispense override needs an entry"),
                DispenseOverrideRequiredCodeRule(message: "dispense override needs this field"),
                DispenseOverrideDiscountRangeRule(min: 5.1, max: 100.5),
                DispenseOverrideAllowedExternalRefRule(allowed: ["manual", "capped", "global"]),
                DispenseOverrideLabelLengthRule(maxLength: 255),
            ]
        )
    }
}
