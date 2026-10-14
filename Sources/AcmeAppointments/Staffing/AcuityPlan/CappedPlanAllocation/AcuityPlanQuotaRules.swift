import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a acuity plan quota must pass. Check returns its problems, or none.
    protocol AcuityPlanQuotaRule {
        func check(_ item: AcuityPlanQuota) -> [String]
    }

    final class AcuityPlanQuotaNameLengthRule: AcuityPlanQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanQuota) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AcuityPlanQuotaRequiredReviewerRule: AcuityPlanQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AcuityPlanQuota) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AcuityPlanQuotaAllowedSummaryRule: AcuityPlanQuotaRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AcuityPlanQuota) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.summary)) {
                return ["summary \(item.summary) is inconsistent"]
            }
            return []
        }
    }

    final class AcuityPlanQuotaReviewerLengthRule: AcuityPlanQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanQuota) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a acuity plan quota.
    final class AcuityPlanQuotaValidator {
        var rules: [any AcuityPlanQuotaRule]

        init(rules: [any AcuityPlanQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: AcuityPlanQuota) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AcuityPlanQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AcuityPlanQuota]) -> [String: [String]] {
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

    static func defaultAcuityPlanQuotaValidator() -> AcuityPlanQuotaValidator {
        return AcuityPlanQuotaValidator(
            rules: [
                AcuityPlanQuotaNameLengthRule(maxLength: 80),
                AcuityPlanQuotaRequiredReviewerRule(message: "acuity plan quota needs this field"),
                AcuityPlanQuotaAllowedSummaryRule(allowed: []),
                AcuityPlanQuotaReviewerLengthRule(maxLength: 86400),
            ]
        )
    }
}
