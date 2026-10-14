import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a weighted priority tier must pass. Check returns its problems, or none.
    protocol WeightedPriorityTierRule {
        func check(_ item: WeightedPriorityTier) -> [String]
    }

    final class WeightedPriorityTierRequiredLabelRule: WeightedPriorityTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedPriorityTier) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedPriorityTierCodePrefixRule: WeightedPriorityTierRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WeightedPriorityTier) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WeightedPriorityTierOwnerIDLengthRule: WeightedPriorityTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedPriorityTier) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedPriorityTierAllowedLabelRule: WeightedPriorityTierRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedPriorityTier) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is too long"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted priority tier.
    final class WeightedPriorityTierValidator {
        var rules: [any WeightedPriorityTierRule]

        init(rules: [any WeightedPriorityTierRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedPriorityTier) -> [String] {
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

        func requireValid(_ item: WeightedPriorityTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedPriorityTier]) -> [String: [String]] {
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

    static func defaultWeightedPriorityTierValidator() -> WeightedPriorityTierValidator {
        return WeightedPriorityTierValidator(
            rules: [
                WeightedPriorityTierRequiredLabelRule(message: "weighted priority tier needs this field"),
                WeightedPriorityTierCodePrefixRule(prefix: "Q"),
                WeightedPriorityTierOwnerIDLengthRule(maxLength: 64),
                WeightedPriorityTierAllowedLabelRule(allowed: ["strict"]),
            ]
        )
    }
}
