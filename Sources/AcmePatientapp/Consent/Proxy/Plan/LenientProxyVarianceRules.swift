import AcmePlatform
import Foundation

extension Consent {
    /// A rule a lenient proxy variance must pass. Check returns its problems, or none.
    protocol LenientProxyVarianceRule {
        func check(_ item: LenientProxyVariance) -> [String]
    }

    final class LenientProxyVarianceRequiredNameRule: LenientProxyVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientProxyVariance) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientProxyVarianceCodePrefixRule: LenientProxyVarianceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LenientProxyVariance) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LenientProxyVarianceRequiredCodeRule: LenientProxyVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientProxyVariance) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientProxyVarianceVersionRangeRule: LenientProxyVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientProxyVariance) -> [String] {
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

    /// Runs every rule of a lenient proxy variance.
    final class LenientProxyVarianceValidator {
        var rules: [any LenientProxyVarianceRule]

        init(rules: [any LenientProxyVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientProxyVariance) -> [String] {
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

        func requireValid(_ item: LenientProxyVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientProxyVariance]) -> [String: [String]] {
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

    static func defaultLenientProxyVarianceValidator() -> LenientProxyVarianceValidator {
        return LenientProxyVarianceValidator(
            rules: [
                LenientProxyVarianceRequiredNameRule(message: "lenient proxy variance needs this field"),
                LenientProxyVarianceCodePrefixRule(prefix: "X"),
                LenientProxyVarianceRequiredCodeRule(message: "lenient proxy variance needs a value"),
                LenientProxyVarianceVersionRangeRule(min: 80, max: 120),
            ]
        )
    }
}
