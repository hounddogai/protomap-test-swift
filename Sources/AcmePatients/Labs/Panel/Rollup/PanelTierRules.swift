import AcmePlatform
import Foundation

extension Labs {
    /// A rule a panel tier must pass. Check returns its problems, or none.
    protocol PanelTierRule {
        func check(_ item: PanelTier) -> [String]
    }

    final class PanelTierCodeLengthRule: PanelTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PanelTier) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PanelTierRequiredLabelRule: PanelTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelTier) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PanelTierRequiredCodeRule: PanelTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelTier) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PanelTierRequiredNameRule: PanelTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelTier) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PanelTierRevisionRangeRule: PanelTierRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PanelTier) -> [String] {
            let value = item.revision
            var problems: [String] = []
            if value < min {
                problems.append("revision \(value) is below \(min)")
            }
            if value > max {
                problems.append("revision \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a panel tier.
    final class PanelTierValidator {
        var rules: [any PanelTierRule]

        init(rules: [any PanelTierRule]) {
            self.rules = rules
        }

        func validate(_ item: PanelTier) -> [String] {
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

        func requireValid(_ item: PanelTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PanelTier]) -> [String: [String]] {
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

    static func defaultPanelTierValidator() -> PanelTierValidator {
        return PanelTierValidator(
            rules: [
                PanelTierCodeLengthRule(maxLength: 32),
                PanelTierRequiredLabelRule(message: "panel tier needs an entry"),
                PanelTierRequiredCodeRule(message: "panel tier needs an entry"),
                PanelTierRequiredNameRule(message: "panel tier needs an entry"),
                PanelTierRevisionRangeRule(min: 255, max: 255),
            ]
        )
    }
}
