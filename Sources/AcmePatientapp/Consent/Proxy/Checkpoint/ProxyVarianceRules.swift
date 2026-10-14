import AcmePlatform
import Foundation

extension Consent {
    /// A rule a proxy variance must pass. Check returns its problems, or none.
    protocol ProxyVarianceRule {
        func check(_ item: ProxyVariance) -> [String]
    }

    final class ProxyVarianceRequiredLocaleRule: ProxyVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyVariance) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProxyVarianceLabelLengthRule: ProxyVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProxyVariance) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProxyVarianceAllowedDiagnosisCodeRule: ProxyVarianceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ProxyVariance) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.diagnosisCode)) {
                return ["diagnosis code \(item.diagnosisCode) is unknown"]
            }
            return []
        }
    }

    final class ProxyVarianceRequiredLabelRule: ProxyVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyVariance) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProxyVarianceRequiredCodeRule: ProxyVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyVariance) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProxyVarianceCodePrefixRule: ProxyVarianceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ProxyVariance) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a proxy variance.
    final class ProxyVarianceValidator {
        var rules: [any ProxyVarianceRule]

        init(rules: [any ProxyVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: ProxyVariance) -> [String] {
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

        func requireValid(_ item: ProxyVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProxyVariance]) -> [String: [String]] {
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

    static func defaultProxyVarianceValidator() -> ProxyVarianceValidator {
        return ProxyVarianceValidator(
            rules: [
                ProxyVarianceRequiredLocaleRule(message: "proxy variance needs an entry"),
                ProxyVarianceLabelLengthRule(maxLength: 3600),
                ProxyVarianceAllowedDiagnosisCodeRule(allowed: ["legacy"]),
                ProxyVarianceRequiredLabelRule(message: "proxy variance needs an entry"),
                ProxyVarianceRequiredCodeRule(message: "proxy variance needs this field"),
                ProxyVarianceCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
