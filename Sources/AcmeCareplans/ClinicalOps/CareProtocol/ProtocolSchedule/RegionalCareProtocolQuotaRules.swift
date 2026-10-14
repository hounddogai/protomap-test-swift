import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a regional care protocol quota must pass. Check returns its problems, or none.
    protocol RegionalCareProtocolQuotaRule {
        func check(_ item: RegionalCareProtocolQuota) -> [String]
    }

    final class RegionalCareProtocolQuotaDescriptionLengthRule: RegionalCareProtocolQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalCareProtocolQuota) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalCareProtocolQuotaRequiredNameRule: RegionalCareProtocolQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalCareProtocolQuota) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalCareProtocolQuotaCodePrefixRule: RegionalCareProtocolQuotaRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalCareProtocolQuota) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RegionalCareProtocolQuotaNameLengthRule: RegionalCareProtocolQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalCareProtocolQuota) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalCareProtocolQuotaRevisionRangeRule: RegionalCareProtocolQuotaRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalCareProtocolQuota) -> [String] {
            let value = item.revision
            var problems: [String] = []
            if value < min {
                problems.append("revision \(value) is below \(min)")
            }
            if value > max {
                problems.append("revision \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a regional care protocol quota.
    final class RegionalCareProtocolQuotaValidator {
        var rules: [any RegionalCareProtocolQuotaRule]

        init(rules: [any RegionalCareProtocolQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalCareProtocolQuota) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalCareProtocolQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalCareProtocolQuota]) -> [String: [String]] {
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

    static func defaultRegionalCareProtocolQuotaValidator() -> RegionalCareProtocolQuotaValidator {
        return RegionalCareProtocolQuotaValidator(
            rules: [
                RegionalCareProtocolQuotaDescriptionLengthRule(maxLength: 1000),
                RegionalCareProtocolQuotaRequiredNameRule(message: "regional care protocol quota needs an entry"),
                RegionalCareProtocolQuotaCodePrefixRule(prefix: "ACM"),
                RegionalCareProtocolQuotaNameLengthRule(maxLength: 255),
                RegionalCareProtocolQuotaRevisionRangeRule(min: 16, max: 64),
            ]
        )
    }
}
