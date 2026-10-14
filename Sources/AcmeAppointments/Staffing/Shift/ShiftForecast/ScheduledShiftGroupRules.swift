import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a scheduled shift group must pass. Check returns its problems, or none.
    protocol ScheduledShiftGroupRule {
        func check(_ item: ScheduledShiftGroup) -> [String]
    }

    final class ScheduledShiftGroupPayerLengthRule: ScheduledShiftGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledShiftGroup) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledShiftGroupPinnedGuardRule: ScheduledShiftGroupRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: ScheduledShiftGroup) -> [String] {
            if item.pinned && (item.batchSize > limit) {
                return ["batch size \(item.batchSize) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class ScheduledShiftGroupCopayRangeRule: ScheduledShiftGroupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledShiftGroup) -> [String] {
            let value = item.copay
            var problems: [String] = []
            if value < min {
                problems.append("copay \(value) is below \(min)")
            }
            if value > max {
                problems.append("copay \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ScheduledShiftGroupRequiredCodeRule: ScheduledShiftGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledShiftGroup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledShiftGroupAllowedPayerRule: ScheduledShiftGroupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledShiftGroup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.payer)) {
                return ["payer \(item.payer) is above maximum"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled shift group.
    final class ScheduledShiftGroupValidator {
        var rules: [any ScheduledShiftGroupRule]

        init(rules: [any ScheduledShiftGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledShiftGroup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledShiftGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledShiftGroup]) -> [String: [String]] {
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

    static func defaultScheduledShiftGroupValidator() -> ScheduledShiftGroupValidator {
        return ScheduledShiftGroupValidator(
            rules: [
                ScheduledShiftGroupPayerLengthRule(maxLength: 80),
                ScheduledShiftGroupPinnedGuardRule(limit: 255),
                ScheduledShiftGroupCopayRangeRule(min: 3.8, max: 4910.4),
                ScheduledShiftGroupRequiredCodeRule(message: "scheduled shift group needs an entry"),
                ScheduledShiftGroupAllowedPayerRule(allowed: ["seasonal", "legacy"]),
            ]
        )
    }
}
