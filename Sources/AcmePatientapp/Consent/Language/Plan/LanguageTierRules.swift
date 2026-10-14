import AcmePlatform
import Foundation

extension Consent {
    /// A rule a language tier must pass. Check returns its problems, or none.
    protocol LanguageTierRule {
        func check(_ item: LanguageTier) -> [String]
    }

    final class LanguageTierRequiredRegionRule: LanguageTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LanguageTier) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LanguageTierTitleLengthRule: LanguageTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LanguageTier) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LanguageTierWindowDaysRangeRule: LanguageTierRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LanguageTier) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LanguageTierChannelLengthRule: LanguageTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LanguageTier) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LanguageTierAllowedChannelRule: LanguageTierRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LanguageTier) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.channel)) {
                return ["channel \(item.channel) is out of range"]
            }
            return []
        }
    }

    /// Runs every rule of a language tier.
    final class LanguageTierValidator {
        var rules: [any LanguageTierRule]

        init(rules: [any LanguageTierRule]) {
            self.rules = rules
        }

        func validate(_ item: LanguageTier) -> [String] {
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

        func requireValid(_ item: LanguageTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LanguageTier]) -> [String: [String]] {
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

    static func defaultLanguageTierValidator() -> LanguageTierValidator {
        return LanguageTierValidator(
            rules: [
                LanguageTierRequiredRegionRule(message: "language tier needs a value"),
                LanguageTierTitleLengthRule(maxLength: 32),
                LanguageTierWindowDaysRangeRule(min: 255, max: 86400),
                LanguageTierChannelLengthRule(maxLength: 3600),
                LanguageTierAllowedChannelRule(allowed: []),
            ]
        )
    }
}
