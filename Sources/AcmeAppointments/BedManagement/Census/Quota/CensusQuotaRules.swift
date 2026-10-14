import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a census quota must pass. Check returns its problems, or none.
    protocol CensusQuotaRule {
        func check(_ item: CensusQuota) -> [String]
    }

    final class CensusQuotaCodeLengthRule: CensusQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusQuota) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CensusQuotaRequiredCountryRule: CensusQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CensusQuota) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CensusQuotaRequiredTimezoneRule: CensusQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CensusQuota) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a census quota.
    final class CensusQuotaValidator {
        var rules: [any CensusQuotaRule]

        init(rules: [any CensusQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: CensusQuota) -> [String] {
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

        func requireValid(_ item: CensusQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CensusQuota]) -> [String: [String]] {
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

    static func defaultCensusQuotaValidator() -> CensusQuotaValidator {
        return CensusQuotaValidator(
            rules: [
                CensusQuotaCodeLengthRule(maxLength: 86400),
                CensusQuotaRequiredCountryRule(message: "census quota needs a value"),
                CensusQuotaRequiredTimezoneRule(message: "census quota needs this field"),
            ]
        )
    }
}
