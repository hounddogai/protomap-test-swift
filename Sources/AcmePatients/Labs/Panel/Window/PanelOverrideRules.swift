import AcmePlatform
import Foundation

extension Labs {
    /// A rule a panel override must pass. Check returns its problems, or none.
    protocol PanelOverrideRule {
        func check(_ item: PanelOverride) -> [String]
    }

    final class PanelOverrideBedLengthRule: PanelOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PanelOverride) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PanelOverrideCodePrefixRule: PanelOverrideRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PanelOverride) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PanelOverrideRequiredCurrencyRule: PanelOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelOverride) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PanelOverrideAcuityRangeRule: PanelOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PanelOverride) -> [String] {
            let value = item.acuity
            var problems: [String] = []
            if value < min {
                problems.append("acuity \(value) is below \(min)")
            }
            if value > max {
                problems.append("acuity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PanelOverrideRequiredBedRule: PanelOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelOverride) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PanelOverrideAllowedBedRule: PanelOverrideRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PanelOverride) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.bed)) {
                return ["bed \(item.bed) is too long"]
            }
            return []
        }
    }

    /// Runs every rule of a panel override.
    final class PanelOverrideValidator {
        var rules: [any PanelOverrideRule]

        init(rules: [any PanelOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: PanelOverride) -> [String] {
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

        func requireValid(_ item: PanelOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PanelOverride]) -> [String: [String]] {
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

    static func defaultPanelOverrideValidator() -> PanelOverrideValidator {
        return PanelOverrideValidator(
            rules: [
                PanelOverrideBedLengthRule(maxLength: 16),
                PanelOverrideCodePrefixRule(prefix: "X"),
                PanelOverrideRequiredCurrencyRule(message: "panel override needs this field"),
                PanelOverrideAcuityRangeRule(min: 16, max: 64),
                PanelOverrideRequiredBedRule(message: "panel override needs an entry"),
                PanelOverrideAllowedBedRule(allowed: []),
            ]
        )
    }
}
