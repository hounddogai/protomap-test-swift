import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a pending follow up override must pass. Check returns its problems, or none.
    protocol PendingFollowUpOverrideRule {
        func check(_ item: PendingFollowUpOverride) -> [String]
    }

    final class PendingFollowUpOverrideFloorValueRangeRule: PendingFollowUpOverrideRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingFollowUpOverride) -> [String] {
            let value = item.floorValue
            var problems: [String] = []
            if value < min {
                problems.append("floor value \(value) is below \(min)")
            }
            if value > max {
                problems.append("floor value \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingFollowUpOverrideAllowedCurrencyRule: PendingFollowUpOverrideRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingFollowUpOverride) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.currency)) {
                return ["currency \(item.currency) is not allowed"]
            }
            return []
        }
    }

    final class PendingFollowUpOverrideRequiredCurrencyRule: PendingFollowUpOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingFollowUpOverride) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingFollowUpOverrideCodeLengthRule: PendingFollowUpOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingFollowUpOverride) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending follow up override.
    final class PendingFollowUpOverrideValidator {
        var rules: [any PendingFollowUpOverrideRule]

        init(rules: [any PendingFollowUpOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingFollowUpOverride) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingFollowUpOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingFollowUpOverride]) -> [String: [String]] {
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

    static func defaultPendingFollowUpOverrideValidator() -> PendingFollowUpOverrideValidator {
        return PendingFollowUpOverrideValidator(
            rules: [
                PendingFollowUpOverrideFloorValueRangeRule(min: 0.8, max: 2028.9),
                PendingFollowUpOverrideAllowedCurrencyRule(allowed: ["scheduled"]),
                PendingFollowUpOverrideRequiredCurrencyRule(message: "pending follow up override needs this field"),
                PendingFollowUpOverrideCodeLengthRule(maxLength: 255),
            ]
        )
    }
}
