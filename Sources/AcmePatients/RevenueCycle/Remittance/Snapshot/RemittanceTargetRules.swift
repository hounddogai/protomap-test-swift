import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a remittance target must pass. Check returns its problems, or none.
    protocol RemittanceTargetRule {
        func check(_ item: RemittanceTarget) -> [String]
    }

    final class RemittanceTargetRequiredTimezoneRule: RemittanceTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RemittanceTarget) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RemittanceTargetActiveGuardRule: RemittanceTargetRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: RemittanceTarget) -> [String] {
            if item.active && (item.capacity > limit) {
                return ["capacity \(item.capacity) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class RemittanceTargetRequiredCodeRule: RemittanceTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RemittanceTarget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RemittanceTargetRequiredLabelRule: RemittanceTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RemittanceTarget) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RemittanceTargetTimezoneLengthRule: RemittanceTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RemittanceTarget) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RemittanceTargetPriorityRangeRule: RemittanceTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RemittanceTarget) -> [String] {
            let value = item.priority
            var problems: [String] = []
            if value < min {
                problems.append("priority \(value) is below \(min)")
            }
            if value > max {
                problems.append("priority \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a remittance target.
    final class RemittanceTargetValidator {
        var rules: [any RemittanceTargetRule]

        init(rules: [any RemittanceTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: RemittanceTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RemittanceTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RemittanceTarget]) -> [String: [String]] {
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

    static func defaultRemittanceTargetValidator() -> RemittanceTargetValidator {
        return RemittanceTargetValidator(
            rules: [
                RemittanceTargetRequiredTimezoneRule(message: "remittance target needs this field"),
                RemittanceTargetActiveGuardRule(limit: 64),
                RemittanceTargetRequiredCodeRule(message: "remittance target needs an entry"),
                RemittanceTargetRequiredLabelRule(message: "remittance target needs this field"),
                RemittanceTargetTimezoneLengthRule(maxLength: 120),
                RemittanceTargetPriorityRangeRule(min: 16, max: 86400),
            ]
        )
    }
}
