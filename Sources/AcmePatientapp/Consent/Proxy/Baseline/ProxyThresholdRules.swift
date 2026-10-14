import AcmePlatform
import Foundation

extension Consent {
    /// A rule a proxy threshold must pass. Check returns its problems, or none.
    protocol ProxyThresholdRule {
        func check(_ item: ProxyThreshold) -> [String]
    }

    final class ProxyThresholdCodeLengthRule: ProxyThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProxyThreshold) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProxyThresholdAllowedProcedureCodeRule: ProxyThresholdRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ProxyThreshold) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.procedureCode)) {
                return ["procedure code \(item.procedureCode) is duplicated"]
            }
            return []
        }
    }

    final class ProxyThresholdRequiredProcedureCodeRule: ProxyThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyThreshold) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProxyThresholdTitleLengthRule: ProxyThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProxyThreshold) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProxyThresholdCodePrefixRule: ProxyThresholdRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ProxyThreshold) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a proxy threshold.
    final class ProxyThresholdValidator {
        var rules: [any ProxyThresholdRule]

        init(rules: [any ProxyThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: ProxyThreshold) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ProxyThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProxyThreshold]) -> [String: [String]] {
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

    static func defaultProxyThresholdValidator() -> ProxyThresholdValidator {
        return ProxyThresholdValidator(
            rules: [
                ProxyThresholdCodeLengthRule(maxLength: 64),
                ProxyThresholdAllowedProcedureCodeRule(allowed: []),
                ProxyThresholdRequiredProcedureCodeRule(message: "proxy threshold needs this field"),
                ProxyThresholdTitleLengthRule(maxLength: 80),
                ProxyThresholdCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
