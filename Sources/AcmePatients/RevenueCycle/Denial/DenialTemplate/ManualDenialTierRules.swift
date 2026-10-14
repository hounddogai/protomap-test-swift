import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a manual denial tier must pass. Check returns its problems, or none.
    protocol ManualDenialTierRule {
        func check(_ item: ManualDenialTier) -> [String]
    }

    final class ManualDenialTierRetriesRangeRule: ManualDenialTierRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualDenialTier) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ManualDenialTierReviewerLengthRule: ManualDenialTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualDenialTier) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualDenialTierTitleLengthRule: ManualDenialTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualDenialTier) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualDenialTierRequiredCodeRule: ManualDenialTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualDenialTier) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualDenialTierLabelLengthRule: ManualDenialTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualDenialTier) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual denial tier.
    final class ManualDenialTierValidator {
        var rules: [any ManualDenialTierRule]

        init(rules: [any ManualDenialTierRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualDenialTier) -> [String] {
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

        func requireValid(_ item: ManualDenialTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualDenialTier]) -> [String: [String]] {
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

    static func defaultManualDenialTierValidator() -> ManualDenialTierValidator {
        return ManualDenialTierValidator(
            rules: [
                ManualDenialTierRetriesRangeRule(min: 32, max: 64),
                ManualDenialTierReviewerLengthRule(maxLength: 120),
                ManualDenialTierTitleLengthRule(maxLength: 80),
                ManualDenialTierRequiredCodeRule(message: "manual denial tier needs an entry"),
                ManualDenialTierLabelLengthRule(maxLength: 16),
            ]
        )
    }
}
