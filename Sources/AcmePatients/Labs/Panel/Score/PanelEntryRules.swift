import AcmePlatform
import Foundation

extension Labs {
    /// A rule a panel entry must pass. Check returns its problems, or none.
    protocol PanelEntryRule {
        func check(_ item: PanelEntry) -> [String]
    }

    final class PanelEntryNameLengthRule: PanelEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PanelEntry) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PanelEntryRequiredSourceRule: PanelEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelEntry) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PanelEntryAllowedCurrencyRule: PanelEntryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PanelEntry) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.currency)) {
                return ["currency \(item.currency) is inconsistent"]
            }
            return []
        }
    }

    final class PanelEntryCreatedAtRangeRule: PanelEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PanelEntry) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a panel entry.
    final class PanelEntryValidator {
        var rules: [any PanelEntryRule]

        init(rules: [any PanelEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: PanelEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PanelEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PanelEntry]) -> [String: [String]] {
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

    static func defaultPanelEntryValidator() -> PanelEntryValidator {
        return PanelEntryValidator(
            rules: [
                PanelEntryNameLengthRule(maxLength: 32),
                PanelEntryRequiredSourceRule(message: "panel entry needs a value"),
                PanelEntryAllowedCurrencyRule(allowed: ["batched", "scheduled"]),
                PanelEntryCreatedAtRangeRule(min: 120, max: 120),
            ]
        )
    }
}
