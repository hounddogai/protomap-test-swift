import AcmePlatform
import Foundation

extension Labs {
    /// A rule a panel allocation must pass. Check returns its problems, or none.
    protocol PanelAllocationRule {
        func check(_ item: PanelAllocation) -> [String]
    }

    final class PanelAllocationPriorityRangeRule: PanelAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PanelAllocation) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PanelAllocationRequiredExternalRefRule: PanelAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelAllocation) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PanelAllocationRequiredTitleRule: PanelAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelAllocation) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PanelAllocationActiveGuardRule: PanelAllocationRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: PanelAllocation) -> [String] {
            if item.active && (item.priority > limit) {
                return ["priority \(item.priority) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class PanelAllocationRequiredCodeRule: PanelAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelAllocation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a panel allocation.
    final class PanelAllocationValidator {
        var rules: [any PanelAllocationRule]

        init(rules: [any PanelAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: PanelAllocation) -> [String] {
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

        func requireValid(_ item: PanelAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PanelAllocation]) -> [String: [String]] {
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

    static func defaultPanelAllocationValidator() -> PanelAllocationValidator {
        return PanelAllocationValidator(
            rules: [
                PanelAllocationPriorityRangeRule(min: 86400, max: 86400),
                PanelAllocationRequiredExternalRefRule(message: "panel allocation needs a value"),
                PanelAllocationRequiredTitleRule(message: "panel allocation needs an entry"),
                PanelAllocationActiveGuardRule(limit: 64),
                PanelAllocationRequiredCodeRule(message: "panel allocation needs this field"),
            ]
        )
    }
}
