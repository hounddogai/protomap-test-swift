import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a capped credential milestone must pass. Check returns its problems, or none.
    protocol CappedCredentialMilestoneRule {
        func check(_ item: CappedCredentialMilestone) -> [String]
    }

    final class CappedCredentialMilestoneQuantityRangeRule: CappedCredentialMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedCredentialMilestone) -> [String] {
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

    final class CappedCredentialMilestoneTitleLengthRule: CappedCredentialMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedCredentialMilestone) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedCredentialMilestoneRequiredChannelRule: CappedCredentialMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedCredentialMilestone) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedCredentialMilestoneCodePrefixRule: CappedCredentialMilestoneRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedCredentialMilestone) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped credential milestone.
    final class CappedCredentialMilestoneValidator {
        var rules: [any CappedCredentialMilestoneRule]

        init(rules: [any CappedCredentialMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedCredentialMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedCredentialMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedCredentialMilestone]) -> [String: [String]] {
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

    static func defaultCappedCredentialMilestoneValidator() -> CappedCredentialMilestoneValidator {
        return CappedCredentialMilestoneValidator(
            rules: [
                CappedCredentialMilestoneQuantityRangeRule(min: 32, max: 80),
                CappedCredentialMilestoneTitleLengthRule(maxLength: 1000),
                CappedCredentialMilestoneRequiredChannelRule(message: "capped credential milestone needs a value"),
                CappedCredentialMilestoneCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
