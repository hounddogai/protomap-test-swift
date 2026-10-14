import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a primary eligibility quota must pass. Check returns its problems, or none.
    protocol PrimaryEligibilityQuotaRule {
        func check(_ item: PrimaryEligibilityQuota) -> [String]
    }

    final class PrimaryEligibilityQuotaDiagnosisCodeLengthRule: PrimaryEligibilityQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryEligibilityQuota) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryEligibilityQuotaCreatedAtRangeRule: PrimaryEligibilityQuotaRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryEligibilityQuota) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PrimaryEligibilityQuotaLabelLengthRule: PrimaryEligibilityQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryEligibilityQuota) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryEligibilityQuotaRetriesRangeRule: PrimaryEligibilityQuotaRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryEligibilityQuota) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a primary eligibility quota.
    final class PrimaryEligibilityQuotaValidator {
        var rules: [any PrimaryEligibilityQuotaRule]

        init(rules: [any PrimaryEligibilityQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryEligibilityQuota) -> [String] {
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

        func requireValid(_ item: PrimaryEligibilityQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryEligibilityQuota]) -> [String: [String]] {
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

    static func defaultPrimaryEligibilityQuotaValidator() -> PrimaryEligibilityQuotaValidator {
        return PrimaryEligibilityQuotaValidator(
            rules: [
                PrimaryEligibilityQuotaDiagnosisCodeLengthRule(maxLength: 120),
                PrimaryEligibilityQuotaCreatedAtRangeRule(min: 255, max: 1000),
                PrimaryEligibilityQuotaLabelLengthRule(maxLength: 120),
                PrimaryEligibilityQuotaRetriesRangeRule(min: 64, max: 255),
            ]
        )
    }
}
