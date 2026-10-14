import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a capped care protocol quota must pass. Check returns its problems, or none.
    protocol CappedCareProtocolQuotaRule {
        func check(_ item: CappedCareProtocolQuota) -> [String]
    }

    final class CappedCareProtocolQuotaAllowedProcedureCodeRule: CappedCareProtocolQuotaRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedCareProtocolQuota) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.procedureCode)) {
                return ["procedure code \(item.procedureCode) is expired"]
            }
            return []
        }
    }

    final class CappedCareProtocolQuotaRequiredCodeRule: CappedCareProtocolQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedCareProtocolQuota) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedCareProtocolQuotaRequiredProcedureCodeRule: CappedCareProtocolQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedCareProtocolQuota) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedCareProtocolQuotaContactEmailLengthRule: CappedCareProtocolQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedCareProtocolQuota) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped care protocol quota.
    final class CappedCareProtocolQuotaValidator {
        var rules: [any CappedCareProtocolQuotaRule]

        init(rules: [any CappedCareProtocolQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedCareProtocolQuota) -> [String] {
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

        func requireValid(_ item: CappedCareProtocolQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedCareProtocolQuota]) -> [String: [String]] {
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

    static func defaultCappedCareProtocolQuotaValidator() -> CappedCareProtocolQuotaValidator {
        return CappedCareProtocolQuotaValidator(
            rules: [
                CappedCareProtocolQuotaAllowedProcedureCodeRule(allowed: ["primary", "legacy", "strict"]),
                CappedCareProtocolQuotaRequiredCodeRule(message: "capped care protocol quota needs a value"),
                CappedCareProtocolQuotaRequiredProcedureCodeRule(
                    message: "capped care protocol quota needs this field"
                ),
                CappedCareProtocolQuotaContactEmailLengthRule(maxLength: 120),
            ]
        )
    }
}
