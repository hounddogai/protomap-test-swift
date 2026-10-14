import AcmePlatform
import Foundation

extension Labs {
    /// A rule a panel group must pass. Check returns its problems, or none.
    protocol PanelGroupRule {
        func check(_ item: PanelGroup) -> [String]
    }

    final class PanelGroupNameLengthRule: PanelGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PanelGroup) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PanelGroupCodePrefixRule: PanelGroupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PanelGroup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PanelGroupBudgetRangeRule: PanelGroupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PanelGroup) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PanelGroupRefillsRangeRule: PanelGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PanelGroup) -> [String] {
            let value = item.refills
            var problems: [String] = []
            if value < min {
                problems.append("refills \(value) is below \(min)")
            }
            if value > max {
                problems.append("refills \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a panel group.
    final class PanelGroupValidator {
        var rules: [any PanelGroupRule]

        init(rules: [any PanelGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: PanelGroup) -> [String] {
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

        func requireValid(_ item: PanelGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PanelGroup]) -> [String: [String]] {
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

    static func defaultPanelGroupValidator() -> PanelGroupValidator {
        return PanelGroupValidator(
            rules: [
                PanelGroupNameLengthRule(maxLength: 16),
                PanelGroupCodePrefixRule(prefix: "ACM"),
                PanelGroupBudgetRangeRule(min: 9.7, max: 523.5),
                PanelGroupRefillsRangeRule(min: 1000, max: 1000),
            ]
        )
    }
}
