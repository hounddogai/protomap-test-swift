import AcmePlatform
import Foundation

extension Labs {
    /// A rule a pending panel milestone must pass. Check returns its problems, or none.
    protocol PendingPanelMilestoneRule {
        func check(_ item: PendingPanelMilestone) -> [String]
    }

    final class PendingPanelMilestoneNameLengthRule: PendingPanelMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingPanelMilestone) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingPanelMilestoneCodePrefixRule: PendingPanelMilestoneRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingPanelMilestone) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PendingPanelMilestoneCodeLengthRule: PendingPanelMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingPanelMilestone) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending panel milestone.
    final class PendingPanelMilestoneValidator {
        var rules: [any PendingPanelMilestoneRule]

        init(rules: [any PendingPanelMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingPanelMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingPanelMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingPanelMilestone]) -> [String: [String]] {
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

    static func defaultPendingPanelMilestoneValidator() -> PendingPanelMilestoneValidator {
        return PendingPanelMilestoneValidator(
            rules: [
                PendingPanelMilestoneNameLengthRule(maxLength: 3600),
                PendingPanelMilestoneCodePrefixRule(prefix: "ACM"),
                PendingPanelMilestoneCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
