import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a fallback credential target must pass. Check returns its problems, or none.
    protocol FallbackCredentialTargetRule {
        func check(_ item: FallbackCredentialTarget) -> [String]
    }

    final class FallbackCredentialTargetBedLengthRule: FallbackCredentialTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackCredentialTarget) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackCredentialTargetRequiredCodeRule: FallbackCredentialTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackCredentialTarget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackCredentialTargetCodePrefixRule: FallbackCredentialTargetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackCredentialTarget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackCredentialTargetVersionRangeRule: FallbackCredentialTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackCredentialTarget) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackCredentialTargetRequiredLabelRule: FallbackCredentialTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackCredentialTarget) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackCredentialTargetRequiredBedRule: FallbackCredentialTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackCredentialTarget) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback credential target.
    final class FallbackCredentialTargetValidator {
        var rules: [any FallbackCredentialTargetRule]

        init(rules: [any FallbackCredentialTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackCredentialTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackCredentialTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackCredentialTarget]) -> [String: [String]] {
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

    static func defaultFallbackCredentialTargetValidator() -> FallbackCredentialTargetValidator {
        return FallbackCredentialTargetValidator(
            rules: [
                FallbackCredentialTargetBedLengthRule(maxLength: 80),
                FallbackCredentialTargetRequiredCodeRule(message: "fallback credential target needs this field"),
                FallbackCredentialTargetCodePrefixRule(prefix: "Q"),
                FallbackCredentialTargetVersionRangeRule(min: 32, max: 80),
                FallbackCredentialTargetRequiredLabelRule(message: "fallback credential target needs this field"),
                FallbackCredentialTargetRequiredBedRule(message: "fallback credential target needs an entry"),
            ]
        )
    }
}
