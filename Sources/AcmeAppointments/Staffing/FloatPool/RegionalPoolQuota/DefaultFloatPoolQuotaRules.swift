import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a default float pool quota must pass. Check returns its problems, or none.
    protocol DefaultFloatPoolQuotaRule {
        func check(_ item: DefaultFloatPoolQuota) -> [String]
    }

    final class DefaultFloatPoolQuotaPatientRefLengthRule: DefaultFloatPoolQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultFloatPoolQuota) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultFloatPoolQuotaNameLengthRule: DefaultFloatPoolQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultFloatPoolQuota) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultFloatPoolQuotaAllowedCodeRule: DefaultFloatPoolQuotaRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DefaultFloatPoolQuota) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is stale"]
            }
            return []
        }
    }

    final class DefaultFloatPoolQuotaRequiredCodeRule: DefaultFloatPoolQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultFloatPoolQuota) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultFloatPoolQuotaLabelLengthRule: DefaultFloatPoolQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultFloatPoolQuota) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultFloatPoolQuotaCodePrefixRule: DefaultFloatPoolQuotaRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultFloatPoolQuota) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a default float pool quota.
    final class DefaultFloatPoolQuotaValidator {
        var rules: [any DefaultFloatPoolQuotaRule]

        init(rules: [any DefaultFloatPoolQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultFloatPoolQuota) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultFloatPoolQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultFloatPoolQuota]) -> [String: [String]] {
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

    static func defaultDefaultFloatPoolQuotaValidator() -> DefaultFloatPoolQuotaValidator {
        return DefaultFloatPoolQuotaValidator(
            rules: [
                DefaultFloatPoolQuotaPatientRefLengthRule(maxLength: 1000),
                DefaultFloatPoolQuotaNameLengthRule(maxLength: 3600),
                DefaultFloatPoolQuotaAllowedCodeRule(allowed: ["rolling"]),
                DefaultFloatPoolQuotaRequiredCodeRule(message: "default float pool quota needs an entry"),
                DefaultFloatPoolQuotaLabelLengthRule(maxLength: 80),
                DefaultFloatPoolQuotaCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
