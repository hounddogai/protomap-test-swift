import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a adaptive remittance quota must pass. Check returns its problems, or none.
    protocol AdaptiveRemittanceQuotaRule {
        func check(_ item: AdaptiveRemittanceQuota) -> [String]
    }

    final class AdaptiveRemittanceQuotaRequiredSegmentRule: AdaptiveRemittanceQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveRemittanceQuota) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveRemittanceQuotaWardLengthRule: AdaptiveRemittanceQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveRemittanceQuota) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveRemittanceQuotaAmountRangeRule: AdaptiveRemittanceQuotaRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveRemittanceQuota) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AdaptiveRemittanceQuotaLabelLengthRule: AdaptiveRemittanceQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveRemittanceQuota) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive remittance quota.
    final class AdaptiveRemittanceQuotaValidator {
        var rules: [any AdaptiveRemittanceQuotaRule]

        init(rules: [any AdaptiveRemittanceQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveRemittanceQuota) -> [String] {
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

        func requireValid(_ item: AdaptiveRemittanceQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveRemittanceQuota]) -> [String: [String]] {
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

    static func defaultAdaptiveRemittanceQuotaValidator() -> AdaptiveRemittanceQuotaValidator {
        return AdaptiveRemittanceQuotaValidator(
            rules: [
                AdaptiveRemittanceQuotaRequiredSegmentRule(message: "adaptive remittance quota needs an entry"),
                AdaptiveRemittanceQuotaWardLengthRule(maxLength: 1000),
                AdaptiveRemittanceQuotaAmountRangeRule(min: 0.4, max: 3490.6),
                AdaptiveRemittanceQuotaLabelLengthRule(maxLength: 64),
            ]
        )
    }
}
