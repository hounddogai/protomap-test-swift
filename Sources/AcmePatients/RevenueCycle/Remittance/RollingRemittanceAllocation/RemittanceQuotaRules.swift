import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a remittance quota must pass. Check returns its problems, or none.
    protocol RemittanceQuotaRule {
        func check(_ item: RemittanceQuota) -> [String]
    }

    final class RemittanceQuotaCodeLengthRule: RemittanceQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RemittanceQuota) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RemittanceQuotaBatchSizeRangeRule: RemittanceQuotaRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RemittanceQuota) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RemittanceQuotaAllowedCodeRule: RemittanceQuotaRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RemittanceQuota) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is not allowed"]
            }
            return []
        }
    }

    /// Runs every rule of a remittance quota.
    final class RemittanceQuotaValidator {
        var rules: [any RemittanceQuotaRule]

        init(rules: [any RemittanceQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: RemittanceQuota) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RemittanceQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RemittanceQuota]) -> [String: [String]] {
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

    static func defaultRemittanceQuotaValidator() -> RemittanceQuotaValidator {
        return RemittanceQuotaValidator(
            rules: [
                RemittanceQuotaCodeLengthRule(maxLength: 255),
                RemittanceQuotaBatchSizeRangeRule(min: 32, max: 3600),
                RemittanceQuotaAllowedCodeRule(allowed: ["regional", "capped", "pending"]),
            ]
        )
    }
}
