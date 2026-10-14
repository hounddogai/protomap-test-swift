import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a charge quota must pass. Check returns its problems, or none.
    protocol ChargeQuotaRule {
        func check(_ item: ChargeQuota) -> [String]
    }

    final class ChargeQuotaRequiredTitleRule: ChargeQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ChargeQuota) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ChargeQuotaRequiredRegionRule: ChargeQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ChargeQuota) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ChargeQuotaRequiredCodeRule: ChargeQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ChargeQuota) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ChargeQuotaRequiredSummaryRule: ChargeQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ChargeQuota) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a charge quota.
    final class ChargeQuotaValidator {
        var rules: [any ChargeQuotaRule]

        init(rules: [any ChargeQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: ChargeQuota) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ChargeQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ChargeQuota]) -> [String: [String]] {
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

    static func defaultChargeQuotaValidator() -> ChargeQuotaValidator {
        return ChargeQuotaValidator(
            rules: [
                ChargeQuotaRequiredTitleRule(message: "charge quota needs a value"),
                ChargeQuotaRequiredRegionRule(message: "charge quota needs this field"),
                ChargeQuotaRequiredCodeRule(message: "charge quota needs this field"),
                ChargeQuotaRequiredSummaryRule(message: "charge quota needs this field"),
            ]
        )
    }
}
