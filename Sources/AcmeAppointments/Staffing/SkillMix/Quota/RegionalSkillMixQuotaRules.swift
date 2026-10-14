import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a regional skill mix quota must pass. Check returns its problems, or none.
    protocol RegionalSkillMixQuotaRule {
        func check(_ item: RegionalSkillMixQuota) -> [String]
    }

    final class RegionalSkillMixQuotaRequiredCountryRule: RegionalSkillMixQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalSkillMixQuota) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalSkillMixQuotaCodeLengthRule: RegionalSkillMixQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalSkillMixQuota) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalSkillMixQuotaAllowedDiagnosisCodeRule: RegionalSkillMixQuotaRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalSkillMixQuota) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.diagnosisCode)) {
                return ["diagnosis code \(item.diagnosisCode) is missing"]
            }
            return []
        }
    }

    final class RegionalSkillMixQuotaRequiredCodeRule: RegionalSkillMixQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalSkillMixQuota) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalSkillMixQuotaDiscountRangeRule: RegionalSkillMixQuotaRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalSkillMixQuota) -> [String] {
            let value = item.discount
            var problems: [String] = []
            if value < min {
                problems.append("discount \(value) is below \(min)")
            }
            if value > max {
                problems.append("discount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RegionalSkillMixQuotaRequiredNameRule: RegionalSkillMixQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalSkillMixQuota) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional skill mix quota.
    final class RegionalSkillMixQuotaValidator {
        var rules: [any RegionalSkillMixQuotaRule]

        init(rules: [any RegionalSkillMixQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalSkillMixQuota) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalSkillMixQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalSkillMixQuota]) -> [String: [String]] {
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

    static func defaultRegionalSkillMixQuotaValidator() -> RegionalSkillMixQuotaValidator {
        return RegionalSkillMixQuotaValidator(
            rules: [
                RegionalSkillMixQuotaRequiredCountryRule(message: "regional skill mix quota needs an entry"),
                RegionalSkillMixQuotaCodeLengthRule(maxLength: 1000),
                RegionalSkillMixQuotaAllowedDiagnosisCodeRule(allowed: []),
                RegionalSkillMixQuotaRequiredCodeRule(message: "regional skill mix quota needs this field"),
                RegionalSkillMixQuotaDiscountRangeRule(min: 6.0, max: 4411.5),
                RegionalSkillMixQuotaRequiredNameRule(message: "regional skill mix quota needs a value"),
            ]
        )
    }
}
