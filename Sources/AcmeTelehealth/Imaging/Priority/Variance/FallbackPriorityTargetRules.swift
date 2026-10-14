import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a fallback priority target must pass. Check returns its problems, or none.
    protocol FallbackPriorityTargetRule {
        func check(_ item: FallbackPriorityTarget) -> [String]
    }

    final class FallbackPriorityTargetRequiredTitleRule: FallbackPriorityTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackPriorityTarget) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackPriorityTargetRequiredCodeRule: FallbackPriorityTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackPriorityTarget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackPriorityTargetTitleLengthRule: FallbackPriorityTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackPriorityTarget) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackPriorityTargetContactEmailLengthRule: FallbackPriorityTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackPriorityTarget) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackPriorityTargetAllowedContactEmailRule: FallbackPriorityTargetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackPriorityTarget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.contactEmail)) {
                return ["contact email \(item.contactEmail) is out of range"]
            }
            return []
        }
    }

    final class FallbackPriorityTargetCodePrefixRule: FallbackPriorityTargetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackPriorityTarget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback priority target.
    final class FallbackPriorityTargetValidator {
        var rules: [any FallbackPriorityTargetRule]

        init(rules: [any FallbackPriorityTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackPriorityTarget) -> [String] {
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

        func requireValid(_ item: FallbackPriorityTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackPriorityTarget]) -> [String: [String]] {
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

    static func defaultFallbackPriorityTargetValidator() -> FallbackPriorityTargetValidator {
        return FallbackPriorityTargetValidator(
            rules: [
                FallbackPriorityTargetRequiredTitleRule(message: "fallback priority target needs a value"),
                FallbackPriorityTargetRequiredCodeRule(message: "fallback priority target needs a value"),
                FallbackPriorityTargetTitleLengthRule(maxLength: 32),
                FallbackPriorityTargetContactEmailLengthRule(maxLength: 86400),
                FallbackPriorityTargetAllowedContactEmailRule(allowed: ["adaptive", "rolling", "strict"]),
                FallbackPriorityTargetCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
