import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a rolling network quota must pass. Check returns its problems, or none.
    protocol RollingNetworkQuotaRule {
        func check(_ item: RollingNetworkQuota) -> [String]
    }

    final class RollingNetworkQuotaCodePrefixRule: RollingNetworkQuotaRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingNetworkQuota) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RollingNetworkQuotaQuantityRangeRule: RollingNetworkQuotaRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingNetworkQuota) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingNetworkQuotaCodeLengthRule: RollingNetworkQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingNetworkQuota) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingNetworkQuotaRequiredAllergyRule: RollingNetworkQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingNetworkQuota) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingNetworkQuotaAcuityRangeRule: RollingNetworkQuotaRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingNetworkQuota) -> [String] {
            let value = item.acuity
            var problems: [String] = []
            if value < min {
                problems.append("acuity \(value) is below \(min)")
            }
            if value > max {
                problems.append("acuity \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a rolling network quota.
    final class RollingNetworkQuotaValidator {
        var rules: [any RollingNetworkQuotaRule]

        init(rules: [any RollingNetworkQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingNetworkQuota) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingNetworkQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingNetworkQuota]) -> [String: [String]] {
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

    static func defaultRollingNetworkQuotaValidator() -> RollingNetworkQuotaValidator {
        return RollingNetworkQuotaValidator(
            rules: [
                RollingNetworkQuotaCodePrefixRule(prefix: "ACM"),
                RollingNetworkQuotaQuantityRangeRule(min: 80, max: 3600),
                RollingNetworkQuotaCodeLengthRule(maxLength: 32),
                RollingNetworkQuotaRequiredAllergyRule(message: "rolling network quota needs an entry"),
                RollingNetworkQuotaAcuityRangeRule(min: 64, max: 120),
            ]
        )
    }
}
