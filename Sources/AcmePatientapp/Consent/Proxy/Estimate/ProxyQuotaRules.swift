import AcmePlatform
import Foundation

extension Consent {
    /// A rule a proxy quota must pass. Check returns its problems, or none.
    protocol ProxyQuotaRule {
        func check(_ item: ProxyQuota) -> [String]
    }

    final class ProxyQuotaLabelLengthRule: ProxyQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProxyQuota) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProxyQuotaRequiredCodeRule: ProxyQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyQuota) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProxyQuotaCodePrefixRule: ProxyQuotaRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ProxyQuota) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ProxyQuotaBudgetRangeRule: ProxyQuotaRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProxyQuota) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ProxyQuotaPinnedGuardRule: ProxyQuotaRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: ProxyQuota) -> [String] {
            if item.pinned && (item.minimum > limit) {
                return ["minimum \(item.minimum) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    /// Runs every rule of a proxy quota.
    final class ProxyQuotaValidator {
        var rules: [any ProxyQuotaRule]

        init(rules: [any ProxyQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: ProxyQuota) -> [String] {
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

        func requireValid(_ item: ProxyQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProxyQuota]) -> [String: [String]] {
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

    static func defaultProxyQuotaValidator() -> ProxyQuotaValidator {
        return ProxyQuotaValidator(
            rules: [
                ProxyQuotaLabelLengthRule(maxLength: 255),
                ProxyQuotaRequiredCodeRule(message: "proxy quota needs a value"),
                ProxyQuotaCodePrefixRule(prefix: "REF"),
                ProxyQuotaBudgetRangeRule(min: 0.9, max: 2702.1),
                ProxyQuotaPinnedGuardRule(limit: 9.5),
            ]
        )
    }
}
