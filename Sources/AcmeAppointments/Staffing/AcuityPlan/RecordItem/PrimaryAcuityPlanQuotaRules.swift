import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a primary acuity plan quota must pass. Check returns its problems, or none.
    protocol PrimaryAcuityPlanQuotaRule {
        func check(_ item: PrimaryAcuityPlanQuota) -> [String]
    }

    final class PrimaryAcuityPlanQuotaCodeLengthRule: PrimaryAcuityPlanQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryAcuityPlanQuota) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryAcuityPlanQuotaRequiredExternalRefRule: PrimaryAcuityPlanQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryAcuityPlanQuota) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryAcuityPlanQuotaDescriptionLengthRule: PrimaryAcuityPlanQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryAcuityPlanQuota) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary acuity plan quota.
    final class PrimaryAcuityPlanQuotaValidator {
        var rules: [any PrimaryAcuityPlanQuotaRule]

        init(rules: [any PrimaryAcuityPlanQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryAcuityPlanQuota) -> [String] {
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

        func requireValid(_ item: PrimaryAcuityPlanQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryAcuityPlanQuota]) -> [String: [String]] {
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

    static func defaultPrimaryAcuityPlanQuotaValidator() -> PrimaryAcuityPlanQuotaValidator {
        return PrimaryAcuityPlanQuotaValidator(
            rules: [
                PrimaryAcuityPlanQuotaCodeLengthRule(maxLength: 3600),
                PrimaryAcuityPlanQuotaRequiredExternalRefRule(message: "primary acuity plan quota needs an entry"),
                PrimaryAcuityPlanQuotaDescriptionLengthRule(maxLength: 120),
            ]
        )
    }
}
