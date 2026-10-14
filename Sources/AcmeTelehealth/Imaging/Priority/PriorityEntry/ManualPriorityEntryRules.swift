import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a manual priority entry must pass. Check returns its problems, or none.
    protocol ManualPriorityEntryRule {
        func check(_ item: ManualPriorityEntry) -> [String]
    }

    final class ManualPriorityEntryCodePrefixRule: ManualPriorityEntryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualPriorityEntry) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ManualPriorityEntryCeilingRangeRule: ManualPriorityEntryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualPriorityEntry) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ManualPriorityEntryFloorValueRangeRule: ManualPriorityEntryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualPriorityEntry) -> [String] {
            let value = item.floorValue
            var problems: [String] = []
            if value < min {
                problems.append("floor value \(value) is below \(min)")
            }
            if value > max {
                problems.append("floor value \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ManualPriorityEntryAllowedCodeRule: ManualPriorityEntryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualPriorityEntry) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is out of range"]
            }
            return []
        }
    }

    final class ManualPriorityEntryRequiredCodeRule: ManualPriorityEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualPriorityEntry) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a manual priority entry.
    final class ManualPriorityEntryValidator {
        var rules: [any ManualPriorityEntryRule]

        init(rules: [any ManualPriorityEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualPriorityEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualPriorityEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualPriorityEntry]) -> [String: [String]] {
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

    static func defaultManualPriorityEntryValidator() -> ManualPriorityEntryValidator {
        return ManualPriorityEntryValidator(
            rules: [
                ManualPriorityEntryCodePrefixRule(prefix: "Q"),
                ManualPriorityEntryCeilingRangeRule(min: 8.1, max: 3698.9),
                ManualPriorityEntryFloorValueRangeRule(min: 2.3, max: 1751.2),
                ManualPriorityEntryAllowedCodeRule(allowed: ["capped"]),
                ManualPriorityEntryRequiredCodeRule(message: "manual priority entry needs this field"),
            ]
        )
    }
}
