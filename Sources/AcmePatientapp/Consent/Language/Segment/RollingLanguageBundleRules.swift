import AcmePlatform
import Foundation

extension Consent {
    /// A rule a rolling language bundle must pass. Check returns its problems, or none.
    protocol RollingLanguageBundleRule {
        func check(_ item: RollingLanguageBundle) -> [String]
    }

    final class RollingLanguageBundleCodePrefixRule: RollingLanguageBundleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingLanguageBundle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RollingLanguageBundleRequiredLabelRule: RollingLanguageBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingLanguageBundle) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingLanguageBundleCodeLengthRule: RollingLanguageBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingLanguageBundle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingLanguageBundleAllowedCodeRule: RollingLanguageBundleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingLanguageBundle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is duplicated"]
            }
            return []
        }
    }

    final class RollingLanguageBundleTimezoneLengthRule: RollingLanguageBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingLanguageBundle) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingLanguageBundleRetriesRangeRule: RollingLanguageBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingLanguageBundle) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling language bundle.
    final class RollingLanguageBundleValidator {
        var rules: [any RollingLanguageBundleRule]

        init(rules: [any RollingLanguageBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingLanguageBundle) -> [String] {
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

        func requireValid(_ item: RollingLanguageBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingLanguageBundle]) -> [String: [String]] {
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

    static func defaultRollingLanguageBundleValidator() -> RollingLanguageBundleValidator {
        return RollingLanguageBundleValidator(
            rules: [
                RollingLanguageBundleCodePrefixRule(prefix: "REF"),
                RollingLanguageBundleRequiredLabelRule(message: "rolling language bundle needs an entry"),
                RollingLanguageBundleCodeLengthRule(maxLength: 3600),
                RollingLanguageBundleAllowedCodeRule(allowed: ["regional", "capped", "capped"]),
                RollingLanguageBundleTimezoneLengthRule(maxLength: 32),
                RollingLanguageBundleRetriesRangeRule(min: 16, max: 86400),
            ]
        )
    }
}
