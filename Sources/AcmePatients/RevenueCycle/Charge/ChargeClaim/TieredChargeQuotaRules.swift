import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a tiered charge quota must pass. Check returns its problems, or none.
    protocol TieredChargeQuotaRule {
        func check(_ item: TieredChargeQuota) -> [String]
    }

    final class TieredChargeQuotaLabelLengthRule: TieredChargeQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredChargeQuota) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredChargeQuotaVisitMinutesRangeRule: TieredChargeQuotaRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredChargeQuota) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredChargeQuotaContactEmailLengthRule: TieredChargeQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredChargeQuota) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredChargeQuotaCeilingRangeRule: TieredChargeQuotaRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredChargeQuota) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TieredChargeQuotaAllowedLabelRule: TieredChargeQuotaRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredChargeQuota) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is below minimum"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered charge quota.
    final class TieredChargeQuotaValidator {
        var rules: [any TieredChargeQuotaRule]

        init(rules: [any TieredChargeQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredChargeQuota) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredChargeQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredChargeQuota]) -> [String: [String]] {
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

    static func defaultTieredChargeQuotaValidator() -> TieredChargeQuotaValidator {
        return TieredChargeQuotaValidator(
            rules: [
                TieredChargeQuotaLabelLengthRule(maxLength: 64),
                TieredChargeQuotaVisitMinutesRangeRule(min: 32, max: 3600),
                TieredChargeQuotaContactEmailLengthRule(maxLength: 120),
                TieredChargeQuotaCeilingRangeRule(min: 5.6, max: 4331.9),
                TieredChargeQuotaAllowedLabelRule(allowed: ["manual"]),
            ]
        )
    }
}
