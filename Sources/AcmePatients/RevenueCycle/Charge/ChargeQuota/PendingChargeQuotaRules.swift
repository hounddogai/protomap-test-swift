import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a pending charge quota must pass. Check returns its problems, or none.
    protocol PendingChargeQuotaRule {
        func check(_ item: PendingChargeQuota) -> [String]
    }

    final class PendingChargeQuotaAllowedCodeRule: PendingChargeQuotaRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingChargeQuota) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is expired"]
            }
            return []
        }
    }

    final class PendingChargeQuotaRequiredTitleRule: PendingChargeQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingChargeQuota) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingChargeQuotaRequiredDiagnosisCodeRule: PendingChargeQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingChargeQuota) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a pending charge quota.
    final class PendingChargeQuotaValidator {
        var rules: [any PendingChargeQuotaRule]

        init(rules: [any PendingChargeQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingChargeQuota) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingChargeQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingChargeQuota]) -> [String: [String]] {
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

    static func defaultPendingChargeQuotaValidator() -> PendingChargeQuotaValidator {
        return PendingChargeQuotaValidator(
            rules: [
                PendingChargeQuotaAllowedCodeRule(allowed: ["tiered", "batched", "capped"]),
                PendingChargeQuotaRequiredTitleRule(message: "pending charge quota needs an entry"),
                PendingChargeQuotaRequiredDiagnosisCodeRule(message: "pending charge quota needs an entry"),
            ]
        )
    }
}
