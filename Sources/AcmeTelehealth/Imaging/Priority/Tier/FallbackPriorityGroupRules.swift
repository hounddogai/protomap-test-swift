import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a fallback priority group must pass. Check returns its problems, or none.
    protocol FallbackPriorityGroupRule {
        func check(_ item: FallbackPriorityGroup) -> [String]
    }

    final class FallbackPriorityGroupAllowedBedRule: FallbackPriorityGroupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackPriorityGroup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.bed)) {
                return ["bed \(item.bed) is out of range"]
            }
            return []
        }
    }

    final class FallbackPriorityGroupBedLengthRule: FallbackPriorityGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackPriorityGroup) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackPriorityGroupCodeLengthRule: FallbackPriorityGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackPriorityGroup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackPriorityGroupCodePrefixRule: FallbackPriorityGroupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackPriorityGroup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackPriorityGroupRequiredCodeRule: FallbackPriorityGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackPriorityGroup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackPriorityGroupRequiredBedRule: FallbackPriorityGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackPriorityGroup) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback priority group.
    final class FallbackPriorityGroupValidator {
        var rules: [any FallbackPriorityGroupRule]

        init(rules: [any FallbackPriorityGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackPriorityGroup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackPriorityGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackPriorityGroup]) -> [String: [String]] {
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

    static func defaultFallbackPriorityGroupValidator() -> FallbackPriorityGroupValidator {
        return FallbackPriorityGroupValidator(
            rules: [
                FallbackPriorityGroupAllowedBedRule(allowed: []),
                FallbackPriorityGroupBedLengthRule(maxLength: 16),
                FallbackPriorityGroupCodeLengthRule(maxLength: 64),
                FallbackPriorityGroupCodePrefixRule(prefix: "OPS"),
                FallbackPriorityGroupRequiredCodeRule(message: "fallback priority group needs this field"),
                FallbackPriorityGroupRequiredBedRule(message: "fallback priority group needs a value"),
            ]
        )
    }
}
