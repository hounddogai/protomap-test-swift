import AcmePlatform
import Foundation

extension Labs {
    /// A rule a panel adjustment must pass. Check returns its problems, or none.
    protocol PanelAdjustmentRule {
        func check(_ item: PanelAdjustment) -> [String]
    }

    final class PanelAdjustmentCodeLengthRule: PanelAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PanelAdjustment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PanelAdjustmentRequiredCodeRule: PanelAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelAdjustment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PanelAdjustmentCodePrefixRule: PanelAdjustmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PanelAdjustment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a panel adjustment.
    final class PanelAdjustmentValidator {
        var rules: [any PanelAdjustmentRule]

        init(rules: [any PanelAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: PanelAdjustment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PanelAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PanelAdjustment]) -> [String: [String]] {
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

    static func defaultPanelAdjustmentValidator() -> PanelAdjustmentValidator {
        return PanelAdjustmentValidator(
            rules: [
                PanelAdjustmentCodeLengthRule(maxLength: 64),
                PanelAdjustmentRequiredCodeRule(message: "panel adjustment needs this field"),
                PanelAdjustmentCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
