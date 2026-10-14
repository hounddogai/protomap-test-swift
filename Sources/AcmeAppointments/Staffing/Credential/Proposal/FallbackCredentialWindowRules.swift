import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a fallback credential window must pass. Check returns its problems, or none.
    protocol FallbackCredentialWindowRule {
        func check(_ item: FallbackCredentialWindow) -> [String]
    }

    final class FallbackCredentialWindowLabelLengthRule: FallbackCredentialWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackCredentialWindow) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackCredentialWindowRequiredLabelRule: FallbackCredentialWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackCredentialWindow) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackCredentialWindowThresholdRangeRule: FallbackCredentialWindowRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackCredentialWindow) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackCredentialWindowRequiredCodeRule: FallbackCredentialWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackCredentialWindow) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackCredentialWindowRequiredTimezoneRule: FallbackCredentialWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackCredentialWindow) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackCredentialWindowCodePrefixRule: FallbackCredentialWindowRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackCredentialWindow) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback credential window.
    final class FallbackCredentialWindowValidator {
        var rules: [any FallbackCredentialWindowRule]

        init(rules: [any FallbackCredentialWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackCredentialWindow) -> [String] {
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

        func requireValid(_ item: FallbackCredentialWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackCredentialWindow]) -> [String: [String]] {
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

    static func defaultFallbackCredentialWindowValidator() -> FallbackCredentialWindowValidator {
        return FallbackCredentialWindowValidator(
            rules: [
                FallbackCredentialWindowLabelLengthRule(maxLength: 64),
                FallbackCredentialWindowRequiredLabelRule(message: "fallback credential window needs a value"),
                FallbackCredentialWindowThresholdRangeRule(min: 8.7, max: 3819.8),
                FallbackCredentialWindowRequiredCodeRule(message: "fallback credential window needs this field"),
                FallbackCredentialWindowRequiredTimezoneRule(message: "fallback credential window needs a value"),
                FallbackCredentialWindowCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
