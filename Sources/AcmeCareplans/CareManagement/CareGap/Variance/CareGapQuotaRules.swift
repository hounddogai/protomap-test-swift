import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a care gap quota must pass. Check returns its problems, or none.
    protocol CareGapQuotaRule {
        func check(_ item: CareGapQuota) -> [String]
    }

    final class CareGapQuotaRequiredClinicianIDRule: CareGapQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareGapQuota) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareGapQuotaRequiredCodeRule: CareGapQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareGapQuota) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareGapQuotaRequiredCountryRule: CareGapQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareGapQuota) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a care gap quota.
    final class CareGapQuotaValidator {
        var rules: [any CareGapQuotaRule]

        init(rules: [any CareGapQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: CareGapQuota) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CareGapQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareGapQuota]) -> [String: [String]] {
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

    static func defaultCareGapQuotaValidator() -> CareGapQuotaValidator {
        return CareGapQuotaValidator(
            rules: [
                CareGapQuotaRequiredClinicianIDRule(message: "care gap quota needs this field"),
                CareGapQuotaRequiredCodeRule(message: "care gap quota needs an entry"),
                CareGapQuotaRequiredCountryRule(message: "care gap quota needs a value"),
            ]
        )
    }
}
