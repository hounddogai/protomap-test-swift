import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a overtime milestone must pass. Check returns its problems, or none.
    protocol OvertimeMilestoneRule {
        func check(_ item: OvertimeMilestone) -> [String]
    }

    final class OvertimeMilestoneCodePrefixRule: OvertimeMilestoneRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: OvertimeMilestone) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class OvertimeMilestoneLabelLengthRule: OvertimeMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OvertimeMilestone) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OvertimeMilestoneRequiredCodeRule: OvertimeMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeMilestone) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OvertimeMilestoneRequiredUnitRule: OvertimeMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeMilestone) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a overtime milestone.
    final class OvertimeMilestoneValidator {
        var rules: [any OvertimeMilestoneRule]

        init(rules: [any OvertimeMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: OvertimeMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: OvertimeMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OvertimeMilestone]) -> [String: [String]] {
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

    static func defaultOvertimeMilestoneValidator() -> OvertimeMilestoneValidator {
        return OvertimeMilestoneValidator(
            rules: [
                OvertimeMilestoneCodePrefixRule(prefix: "ACM"),
                OvertimeMilestoneLabelLengthRule(maxLength: 80),
                OvertimeMilestoneRequiredCodeRule(message: "overtime milestone needs an entry"),
                OvertimeMilestoneRequiredUnitRule(message: "overtime milestone needs an entry"),
            ]
        )
    }
}
