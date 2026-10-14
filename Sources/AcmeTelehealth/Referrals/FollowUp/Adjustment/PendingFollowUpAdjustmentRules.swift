import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a pending follow up adjustment must pass. Check returns its problems, or none.
    protocol PendingFollowUpAdjustmentRule {
        func check(_ item: PendingFollowUpAdjustment) -> [String]
    }

    final class PendingFollowUpAdjustmentRequiredNameRule: PendingFollowUpAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingFollowUpAdjustment) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingFollowUpAdjustmentRequiredFacilityRule: PendingFollowUpAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingFollowUpAdjustment) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingFollowUpAdjustmentFacilityLengthRule: PendingFollowUpAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingFollowUpAdjustment) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingFollowUpAdjustmentGraceDaysRangeRule: PendingFollowUpAdjustmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingFollowUpAdjustment) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending follow up adjustment.
    final class PendingFollowUpAdjustmentValidator {
        var rules: [any PendingFollowUpAdjustmentRule]

        init(rules: [any PendingFollowUpAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingFollowUpAdjustment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingFollowUpAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingFollowUpAdjustment]) -> [String: [String]] {
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

    static func defaultPendingFollowUpAdjustmentValidator() -> PendingFollowUpAdjustmentValidator {
        return PendingFollowUpAdjustmentValidator(
            rules: [
                PendingFollowUpAdjustmentRequiredNameRule(message: "pending follow up adjustment needs a value"),
                PendingFollowUpAdjustmentRequiredFacilityRule(message: "pending follow up adjustment needs an entry"),
                PendingFollowUpAdjustmentFacilityLengthRule(maxLength: 1000),
                PendingFollowUpAdjustmentGraceDaysRangeRule(min: 255, max: 1000),
            ]
        )
    }
}
