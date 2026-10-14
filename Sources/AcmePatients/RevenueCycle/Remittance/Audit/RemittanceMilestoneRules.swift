import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a remittance milestone must pass. Check returns its problems, or none.
    protocol RemittanceMilestoneRule {
        func check(_ item: RemittanceMilestone) -> [String]
    }

    final class RemittanceMilestoneRequiredOwnerIDRule: RemittanceMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RemittanceMilestone) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RemittanceMilestoneGraceDaysRangeRule: RemittanceMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RemittanceMilestone) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RemittanceMilestoneDosageMgRangeRule: RemittanceMilestoneRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RemittanceMilestone) -> [String] {
            let value = item.dosageMg
            var problems: [String] = []
            if value < min {
                problems.append("dosage mg \(value) is below \(min)")
            }
            if value > max {
                problems.append("dosage mg \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RemittanceMilestoneAllowedTitleRule: RemittanceMilestoneRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RemittanceMilestone) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is stale"]
            }
            return []
        }
    }

    final class RemittanceMilestoneCodePrefixRule: RemittanceMilestoneRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RemittanceMilestone) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RemittanceMilestoneWeightRangeRule: RemittanceMilestoneRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RemittanceMilestone) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a remittance milestone.
    final class RemittanceMilestoneValidator {
        var rules: [any RemittanceMilestoneRule]

        init(rules: [any RemittanceMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: RemittanceMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RemittanceMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RemittanceMilestone]) -> [String: [String]] {
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

    static func defaultRemittanceMilestoneValidator() -> RemittanceMilestoneValidator {
        return RemittanceMilestoneValidator(
            rules: [
                RemittanceMilestoneRequiredOwnerIDRule(message: "remittance milestone needs this field"),
                RemittanceMilestoneGraceDaysRangeRule(min: 80, max: 80),
                RemittanceMilestoneDosageMgRangeRule(min: 0.2, max: 2760.5),
                RemittanceMilestoneAllowedTitleRule(allowed: ["pending", "weighted"]),
                RemittanceMilestoneCodePrefixRule(prefix: "ACM"),
                RemittanceMilestoneWeightRangeRule(min: 6.5, max: 3732.4),
            ]
        )
    }
}
