import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a credential quota must pass. Check returns its problems, or none.
    protocol CredentialQuotaRule {
        func check(_ item: CredentialQuota) -> [String]
    }

    final class CredentialQuotaArchivedGuardRule: CredentialQuotaRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: CredentialQuota) -> [String] {
            if item.archived && (item.score > limit) {
                return ["score \(item.score) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class CredentialQuotaMarginRangeRule: CredentialQuotaRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CredentialQuota) -> [String] {
            let value = item.margin
            var problems: [String] = []
            if value < min {
                problems.append("margin \(value) is below \(min)")
            }
            if value > max {
                problems.append("margin \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CredentialQuotaRequiredNameRule: CredentialQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialQuota) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CredentialQuotaCodeLengthRule: CredentialQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialQuota) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a credential quota.
    final class CredentialQuotaValidator {
        var rules: [any CredentialQuotaRule]

        init(rules: [any CredentialQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: CredentialQuota) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CredentialQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CredentialQuota]) -> [String: [String]] {
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

    static func defaultCredentialQuotaValidator() -> CredentialQuotaValidator {
        return CredentialQuotaValidator(
            rules: [
                CredentialQuotaArchivedGuardRule(limit: 8.6),
                CredentialQuotaMarginRangeRule(min: 7.6, max: 618.4),
                CredentialQuotaRequiredNameRule(message: "credential quota needs this field"),
                CredentialQuotaCodeLengthRule(maxLength: 1000),
            ]
        )
    }
}
