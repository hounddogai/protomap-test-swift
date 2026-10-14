import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a interaction quota must pass. Check returns its problems, or none.
    protocol InteractionQuotaRule {
        func check(_ item: InteractionQuota) -> [String]
    }

    final class InteractionQuotaCeilingRangeRule: InteractionQuotaRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: InteractionQuota) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class InteractionQuotaAllowedChecksumRule: InteractionQuotaRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: InteractionQuota) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.checksum)) {
                return ["checksum \(item.checksum) is inconsistent"]
            }
            return []
        }
    }

    final class InteractionQuotaDiscountRangeRule: InteractionQuotaRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: InteractionQuota) -> [String] {
            let value = item.discount
            var problems: [String] = []
            if value < min {
                problems.append("discount \(value) is below \(min)")
            }
            if value > max {
                problems.append("discount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class InteractionQuotaRequiredUnitRule: InteractionQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InteractionQuota) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InteractionQuotaChecksumLengthRule: InteractionQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InteractionQuota) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a interaction quota.
    final class InteractionQuotaValidator {
        var rules: [any InteractionQuotaRule]

        init(rules: [any InteractionQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: InteractionQuota) -> [String] {
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

        func requireValid(_ item: InteractionQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InteractionQuota]) -> [String: [String]] {
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

    static func defaultInteractionQuotaValidator() -> InteractionQuotaValidator {
        return InteractionQuotaValidator(
            rules: [
                InteractionQuotaCeilingRangeRule(min: 9.0, max: 1821.7),
                InteractionQuotaAllowedChecksumRule(allowed: ["primary", "legacy", "seasonal"]),
                InteractionQuotaDiscountRangeRule(min: 2.9, max: 3059.8),
                InteractionQuotaRequiredUnitRule(message: "interaction quota needs a value"),
                InteractionQuotaChecksumLengthRule(maxLength: 64),
            ]
        )
    }
}
