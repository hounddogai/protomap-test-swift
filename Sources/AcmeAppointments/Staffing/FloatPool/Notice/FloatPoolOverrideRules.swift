import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a float pool override must pass. Check returns its problems, or none.
    protocol FloatPoolOverrideRule {
        func check(_ item: FloatPoolOverride) -> [String]
    }

    final class FloatPoolOverrideRequiredCodeRule: FloatPoolOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FloatPoolOverride) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FloatPoolOverrideRequiredChannelRule: FloatPoolOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FloatPoolOverride) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FloatPoolOverrideAllowedCodeRule: FloatPoolOverrideRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FloatPoolOverride) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is too long"]
            }
            return []
        }
    }

    final class FloatPoolOverrideLabelLengthRule: FloatPoolOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FloatPoolOverride) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a float pool override.
    final class FloatPoolOverrideValidator {
        var rules: [any FloatPoolOverrideRule]

        init(rules: [any FloatPoolOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: FloatPoolOverride) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FloatPoolOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FloatPoolOverride]) -> [String: [String]] {
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

    static func defaultFloatPoolOverrideValidator() -> FloatPoolOverrideValidator {
        return FloatPoolOverrideValidator(
            rules: [
                FloatPoolOverrideRequiredCodeRule(message: "float pool override needs a value"),
                FloatPoolOverrideRequiredChannelRule(message: "float pool override needs an entry"),
                FloatPoolOverrideAllowedCodeRule(allowed: ["capped", "scheduled", "strict"]),
                FloatPoolOverrideLabelLengthRule(maxLength: 16),
            ]
        )
    }
}
