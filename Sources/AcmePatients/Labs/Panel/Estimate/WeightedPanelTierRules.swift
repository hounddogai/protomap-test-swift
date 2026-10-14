import AcmePlatform
import Foundation

extension Labs {
    /// A rule a weighted panel tier must pass. Check returns its problems, or none.
    protocol WeightedPanelTierRule {
        func check(_ item: WeightedPanelTier) -> [String]
    }

    final class WeightedPanelTierRequiredCodeRule: WeightedPanelTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedPanelTier) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedPanelTierCodePrefixRule: WeightedPanelTierRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WeightedPanelTier) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WeightedPanelTierSequenceRangeRule: WeightedPanelTierRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedPanelTier) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WeightedPanelTierBedLengthRule: WeightedPanelTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedPanelTier) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedPanelTierRequiredLabelRule: WeightedPanelTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedPanelTier) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedPanelTierLabelLengthRule: WeightedPanelTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedPanelTier) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted panel tier.
    final class WeightedPanelTierValidator {
        var rules: [any WeightedPanelTierRule]

        init(rules: [any WeightedPanelTierRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedPanelTier) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedPanelTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedPanelTier]) -> [String: [String]] {
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

    static func defaultWeightedPanelTierValidator() -> WeightedPanelTierValidator {
        return WeightedPanelTierValidator(
            rules: [
                WeightedPanelTierRequiredCodeRule(message: "weighted panel tier needs this field"),
                WeightedPanelTierCodePrefixRule(prefix: "ACM"),
                WeightedPanelTierSequenceRangeRule(min: 80, max: 255),
                WeightedPanelTierBedLengthRule(maxLength: 16),
                WeightedPanelTierRequiredLabelRule(message: "weighted panel tier needs this field"),
                WeightedPanelTierLabelLengthRule(maxLength: 16),
            ]
        )
    }
}
