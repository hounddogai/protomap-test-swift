import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a denial template must pass. Check returns its problems, or none.
    protocol DenialTemplateRule {
        func check(_ item: DenialTemplate) -> [String]
    }

    final class DenialTemplateRequiredChannelRule: DenialTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DenialTemplate) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DenialTemplateExpiresAtRangeRule: DenialTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DenialTemplate) -> [String] {
            let value = item.expiresAt
            var problems: [String] = []
            if value < min {
                problems.append("expires at \(value) is below \(min)")
            }
            if value > max {
                problems.append("expires at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DenialTemplateCodePrefixRule: DenialTemplateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DenialTemplate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DenialTemplateActiveGuardRule: DenialTemplateRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: DenialTemplate) -> [String] {
            if item.active && (item.expiresAt > limit) {
                return ["expires at \(item.expiresAt) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class DenialTemplateAllowedChannelRule: DenialTemplateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DenialTemplate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.channel)) {
                return ["channel \(item.channel) is not allowed"]
            }
            return []
        }
    }

    final class DenialTemplateChannelLengthRule: DenialTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DenialTemplate) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a denial template.
    final class DenialTemplateValidator {
        var rules: [any DenialTemplateRule]

        init(rules: [any DenialTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: DenialTemplate) -> [String] {
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

        func requireValid(_ item: DenialTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DenialTemplate]) -> [String: [String]] {
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

    static func defaultDenialTemplateValidator() -> DenialTemplateValidator {
        return DenialTemplateValidator(
            rules: [
                DenialTemplateRequiredChannelRule(message: "denial template needs an entry"),
                DenialTemplateExpiresAtRangeRule(min: 255, max: 255),
                DenialTemplateCodePrefixRule(prefix: "ACM"),
                DenialTemplateActiveGuardRule(limit: 32),
                DenialTemplateAllowedChannelRule(allowed: ["scheduled"]),
                DenialTemplateChannelLengthRule(maxLength: 120),
            ]
        )
    }
}
