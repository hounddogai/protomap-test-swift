import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a strict follow up adjustment must pass. Check returns its problems, or none.
    protocol StrictFollowUpAdjustmentRule {
        func check(_ item: StrictFollowUpAdjustment) -> [String]
    }

    final class StrictFollowUpAdjustmentRequiredRegionRule: StrictFollowUpAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictFollowUpAdjustment) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictFollowUpAdjustmentCodePrefixRule: StrictFollowUpAdjustmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StrictFollowUpAdjustment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StrictFollowUpAdjustmentRegionLengthRule: StrictFollowUpAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictFollowUpAdjustment) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictFollowUpAdjustmentCreatedAtRangeRule: StrictFollowUpAdjustmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictFollowUpAdjustment) -> [String] {
            let value = item.createdAt
            var problems: [String] = []
            if value < min {
                problems.append("created at \(value) is below \(min)")
            }
            if value > max {
                problems.append("created at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a strict follow up adjustment.
    final class StrictFollowUpAdjustmentValidator {
        var rules: [any StrictFollowUpAdjustmentRule]

        init(rules: [any StrictFollowUpAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictFollowUpAdjustment) -> [String] {
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

        func requireValid(_ item: StrictFollowUpAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictFollowUpAdjustment]) -> [String: [String]] {
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

    static func defaultStrictFollowUpAdjustmentValidator() -> StrictFollowUpAdjustmentValidator {
        return StrictFollowUpAdjustmentValidator(
            rules: [
                StrictFollowUpAdjustmentRequiredRegionRule(message: "strict follow up adjustment needs this field"),
                StrictFollowUpAdjustmentCodePrefixRule(prefix: "X"),
                StrictFollowUpAdjustmentRegionLengthRule(maxLength: 86400),
                StrictFollowUpAdjustmentCreatedAtRangeRule(min: 80, max: 86400),
            ]
        )
    }
}
