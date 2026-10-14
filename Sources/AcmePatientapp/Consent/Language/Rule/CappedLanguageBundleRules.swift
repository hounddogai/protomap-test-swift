import AcmePlatform
import Foundation

extension Consent {
    /// A rule a capped language bundle must pass. Check returns its problems, or none.
    protocol CappedLanguageBundleRule {
        func check(_ item: CappedLanguageBundle) -> [String]
    }

    final class CappedLanguageBundleCodePrefixRule: CappedLanguageBundleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedLanguageBundle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedLanguageBundleRequiredChannelRule: CappedLanguageBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedLanguageBundle) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedLanguageBundleVisibleGuardRule: CappedLanguageBundleRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: CappedLanguageBundle) -> [String] {
            if item.visible && (item.score > limit) {
                return ["score \(item.score) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class CappedLanguageBundleScoreRangeRule: CappedLanguageBundleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedLanguageBundle) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped language bundle.
    final class CappedLanguageBundleValidator {
        var rules: [any CappedLanguageBundleRule]

        init(rules: [any CappedLanguageBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedLanguageBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedLanguageBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedLanguageBundle]) -> [String: [String]] {
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

    static func defaultCappedLanguageBundleValidator() -> CappedLanguageBundleValidator {
        return CappedLanguageBundleValidator(
            rules: [
                CappedLanguageBundleCodePrefixRule(prefix: "OPS"),
                CappedLanguageBundleRequiredChannelRule(message: "capped language bundle needs this field"),
                CappedLanguageBundleVisibleGuardRule(limit: 6.8),
                CappedLanguageBundleScoreRangeRule(min: 2.5, max: 1289.4),
            ]
        )
    }
}
