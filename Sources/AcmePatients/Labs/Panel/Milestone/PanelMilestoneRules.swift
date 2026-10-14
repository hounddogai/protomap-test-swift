import AcmePlatform
import Foundation

extension Labs {
    /// A rule a panel milestone must pass. Check returns its problems, or none.
    protocol PanelMilestoneRule {
        func check(_ item: PanelMilestone) -> [String]
    }

    final class PanelMilestoneRequiredRegionRule: PanelMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelMilestone) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PanelMilestoneAttemptsRangeRule: PanelMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PanelMilestone) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PanelMilestoneNameLengthRule: PanelMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PanelMilestone) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PanelMilestoneRegionLengthRule: PanelMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PanelMilestone) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PanelMilestoneRequiredCodeRule: PanelMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelMilestone) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a panel milestone.
    final class PanelMilestoneValidator {
        var rules: [any PanelMilestoneRule]

        init(rules: [any PanelMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: PanelMilestone) -> [String] {
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

        func requireValid(_ item: PanelMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PanelMilestone]) -> [String: [String]] {
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

    static func defaultPanelMilestoneValidator() -> PanelMilestoneValidator {
        return PanelMilestoneValidator(
            rules: [
                PanelMilestoneRequiredRegionRule(message: "panel milestone needs this field"),
                PanelMilestoneAttemptsRangeRule(min: 1000, max: 1000),
                PanelMilestoneNameLengthRule(maxLength: 120),
                PanelMilestoneRegionLengthRule(maxLength: 80),
                PanelMilestoneRequiredCodeRule(message: "panel milestone needs an entry"),
            ]
        )
    }
}
