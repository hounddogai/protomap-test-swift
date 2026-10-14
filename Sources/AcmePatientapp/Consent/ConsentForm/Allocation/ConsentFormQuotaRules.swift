import AcmePlatform
import Foundation

extension Consent {
    /// A rule a consent form quota must pass. Check returns its problems, or none.
    protocol ConsentFormQuotaRule {
        func check(_ item: ConsentFormQuota) -> [String]
    }

    final class ConsentFormQuotaTitleLengthRule: ConsentFormQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ConsentFormQuota) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ConsentFormQuotaCategoryLengthRule: ConsentFormQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ConsentFormQuota) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ConsentFormQuotaAllowedCategoryRule: ConsentFormQuotaRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ConsentFormQuota) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.category)) {
                return ["category \(item.category) is blocked"]
            }
            return []
        }
    }

    /// Runs every rule of a consent form quota.
    final class ConsentFormQuotaValidator {
        var rules: [any ConsentFormQuotaRule]

        init(rules: [any ConsentFormQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: ConsentFormQuota) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ConsentFormQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ConsentFormQuota]) -> [String: [String]] {
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

    static func defaultConsentFormQuotaValidator() -> ConsentFormQuotaValidator {
        return ConsentFormQuotaValidator(
            rules: [
                ConsentFormQuotaTitleLengthRule(maxLength: 120),
                ConsentFormQuotaCategoryLengthRule(maxLength: 1000),
                ConsentFormQuotaAllowedCategoryRule(allowed: ["lenient", "rolling"]),
            ]
        )
    }
}
