import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a pending alert quota must pass. Check returns its problems, or none.
    protocol PendingAlertQuotaRule {
        func check(_ item: PendingAlertQuota) -> [String]
    }

    final class PendingAlertQuotaRequiredSegmentRule: PendingAlertQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingAlertQuota) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingAlertQuotaTitleLengthRule: PendingAlertQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingAlertQuota) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingAlertQuotaCodeLengthRule: PendingAlertQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingAlertQuota) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingAlertQuotaRefillsRangeRule: PendingAlertQuotaRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingAlertQuota) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingAlertQuotaAmountRangeRule: PendingAlertQuotaRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingAlertQuota) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending alert quota.
    final class PendingAlertQuotaValidator {
        var rules: [any PendingAlertQuotaRule]

        init(rules: [any PendingAlertQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingAlertQuota) -> [String] {
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

        func requireValid(_ item: PendingAlertQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingAlertQuota]) -> [String: [String]] {
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

    static func defaultPendingAlertQuotaValidator() -> PendingAlertQuotaValidator {
        return PendingAlertQuotaValidator(
            rules: [
                PendingAlertQuotaRequiredSegmentRule(message: "pending alert quota needs a value"),
                PendingAlertQuotaTitleLengthRule(maxLength: 80),
                PendingAlertQuotaCodeLengthRule(maxLength: 255),
                PendingAlertQuotaRefillsRangeRule(min: 120, max: 120),
                PendingAlertQuotaAmountRangeRule(min: 0.3, max: 1125.8),
            ]
        )
    }
}
