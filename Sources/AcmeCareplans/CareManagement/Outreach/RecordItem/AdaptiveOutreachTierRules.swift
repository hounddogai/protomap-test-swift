import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a adaptive outreach tier must pass. Check returns its problems, or none.
    protocol AdaptiveOutreachTierRule {
        func check(_ item: AdaptiveOutreachTier) -> [String]
    }

    final class AdaptiveOutreachTierTitleLengthRule: AdaptiveOutreachTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveOutreachTier) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveOutreachTierCodePrefixRule: AdaptiveOutreachTierRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveOutreachTier) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveOutreachTierRequiredRegionRule: AdaptiveOutreachTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveOutreachTier) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveOutreachTierRequiredTitleRule: AdaptiveOutreachTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveOutreachTier) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveOutreachTierAllowedCodeRule: AdaptiveOutreachTierRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveOutreachTier) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is out of range"]
            }
            return []
        }
    }

    final class AdaptiveOutreachTierPriorityRangeRule: AdaptiveOutreachTierRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveOutreachTier) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive outreach tier.
    final class AdaptiveOutreachTierValidator {
        var rules: [any AdaptiveOutreachTierRule]

        init(rules: [any AdaptiveOutreachTierRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveOutreachTier) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveOutreachTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveOutreachTier]) -> [String: [String]] {
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

    static func defaultAdaptiveOutreachTierValidator() -> AdaptiveOutreachTierValidator {
        return AdaptiveOutreachTierValidator(
            rules: [
                AdaptiveOutreachTierTitleLengthRule(maxLength: 32),
                AdaptiveOutreachTierCodePrefixRule(prefix: "REF"),
                AdaptiveOutreachTierRequiredRegionRule(message: "adaptive outreach tier needs a value"),
                AdaptiveOutreachTierRequiredTitleRule(message: "adaptive outreach tier needs this field"),
                AdaptiveOutreachTierAllowedCodeRule(allowed: ["weighted"]),
                AdaptiveOutreachTierPriorityRangeRule(min: 64, max: 1000),
            ]
        )
    }
}
