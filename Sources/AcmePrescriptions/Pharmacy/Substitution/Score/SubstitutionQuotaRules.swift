import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a substitution quota must pass. Check returns its problems, or none.
    protocol SubstitutionQuotaRule {
        func check(_ item: SubstitutionQuota) -> [String]
    }

    final class SubstitutionQuotaLimitRangeRule: SubstitutionQuotaRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SubstitutionQuota) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SubstitutionQuotaAllowedCodeRule: SubstitutionQuotaRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SubstitutionQuota) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is not allowed"]
            }
            return []
        }
    }

    final class SubstitutionQuotaRequiredPhoneRule: SubstitutionQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SubstitutionQuota) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SubstitutionQuotaPhoneLengthRule: SubstitutionQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SubstitutionQuota) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SubstitutionQuotaRequiredLabelRule: SubstitutionQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SubstitutionQuota) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SubstitutionQuotaLabelLengthRule: SubstitutionQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SubstitutionQuota) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a substitution quota.
    final class SubstitutionQuotaValidator {
        var rules: [any SubstitutionQuotaRule]

        init(rules: [any SubstitutionQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: SubstitutionQuota) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SubstitutionQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SubstitutionQuota]) -> [String: [String]] {
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

    static func defaultSubstitutionQuotaValidator() -> SubstitutionQuotaValidator {
        return SubstitutionQuotaValidator(
            rules: [
                SubstitutionQuotaLimitRangeRule(min: 80, max: 120),
                SubstitutionQuotaAllowedCodeRule(allowed: []),
                SubstitutionQuotaRequiredPhoneRule(message: "substitution quota needs a value"),
                SubstitutionQuotaPhoneLengthRule(maxLength: 16),
                SubstitutionQuotaRequiredLabelRule(message: "substitution quota needs an entry"),
                SubstitutionQuotaLabelLengthRule(maxLength: 120),
            ]
        )
    }
}
