import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a rolling rounding quota must pass. Check returns its problems, or none.
    protocol RollingRoundingQuotaRule {
        func check(_ item: RollingRoundingQuota) -> [String]
    }

    final class RollingRoundingQuotaRequiredNameRule: RollingRoundingQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingRoundingQuota) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingRoundingQuotaRequiredTitleRule: RollingRoundingQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingRoundingQuota) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingRoundingQuotaTitleLengthRule: RollingRoundingQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingRoundingQuota) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingRoundingQuotaCodeLengthRule: RollingRoundingQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingRoundingQuota) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingRoundingQuotaQuantityRangeRule: RollingRoundingQuotaRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingRoundingQuota) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingRoundingQuotaRequiredCodeRule: RollingRoundingQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingRoundingQuota) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rolling rounding quota.
    final class RollingRoundingQuotaValidator {
        var rules: [any RollingRoundingQuotaRule]

        init(rules: [any RollingRoundingQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingRoundingQuota) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingRoundingQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingRoundingQuota]) -> [String: [String]] {
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

    static func defaultRollingRoundingQuotaValidator() -> RollingRoundingQuotaValidator {
        return RollingRoundingQuotaValidator(
            rules: [
                RollingRoundingQuotaRequiredNameRule(message: "rolling rounding quota needs a value"),
                RollingRoundingQuotaRequiredTitleRule(message: "rolling rounding quota needs this field"),
                RollingRoundingQuotaTitleLengthRule(maxLength: 64),
                RollingRoundingQuotaCodeLengthRule(maxLength: 80),
                RollingRoundingQuotaQuantityRangeRule(min: 1000, max: 3600),
                RollingRoundingQuotaRequiredCodeRule(message: "rolling rounding quota needs a value"),
            ]
        )
    }
}
