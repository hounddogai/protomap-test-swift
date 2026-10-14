import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a pending modality quota must pass. Check returns its problems, or none.
    protocol PendingModalityQuotaRule {
        func check(_ item: PendingModalityQuota) -> [String]
    }

    final class PendingModalityQuotaAllowedCodeRule: PendingModalityQuotaRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingModalityQuota) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is not allowed"]
            }
            return []
        }
    }

    final class PendingModalityQuotaRequiredAllergyRule: PendingModalityQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingModalityQuota) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingModalityQuotaBatchSizeRangeRule: PendingModalityQuotaRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingModalityQuota) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending modality quota.
    final class PendingModalityQuotaValidator {
        var rules: [any PendingModalityQuotaRule]

        init(rules: [any PendingModalityQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingModalityQuota) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingModalityQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingModalityQuota]) -> [String: [String]] {
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

    static func defaultPendingModalityQuotaValidator() -> PendingModalityQuotaValidator {
        return PendingModalityQuotaValidator(
            rules: [
                PendingModalityQuotaAllowedCodeRule(allowed: ["default", "default", "default"]),
                PendingModalityQuotaRequiredAllergyRule(message: "pending modality quota needs this field"),
                PendingModalityQuotaBatchSizeRangeRule(min: 3600, max: 86400),
            ]
        )
    }
}
