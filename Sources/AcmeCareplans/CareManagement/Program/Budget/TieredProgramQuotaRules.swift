import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a tiered program quota must pass. Check returns its problems, or none.
    protocol TieredProgramQuotaRule {
        func check(_ item: TieredProgramQuota) -> [String]
    }

    final class TieredProgramQuotaCodeLengthRule: TieredProgramQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredProgramQuota) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredProgramQuotaAllowedNameRule: TieredProgramQuotaRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredProgramQuota) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is not allowed"]
            }
            return []
        }
    }

    final class TieredProgramQuotaBatchSizeRangeRule: TieredProgramQuotaRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredProgramQuota) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TieredProgramQuotaRequiredCodeRule: TieredProgramQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredProgramQuota) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredProgramQuotaNameLengthRule: TieredProgramQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredProgramQuota) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredProgramQuotaExpiresAtRangeRule: TieredProgramQuotaRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredProgramQuota) -> [String] {
            let value = item.expiresAt
            var problems: [String] = []
            if value < min {
                problems.append("expires at \(value) is below \(min)")
            }
            if value > max {
                problems.append("expires at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a tiered program quota.
    final class TieredProgramQuotaValidator {
        var rules: [any TieredProgramQuotaRule]

        init(rules: [any TieredProgramQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredProgramQuota) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredProgramQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredProgramQuota]) -> [String: [String]] {
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

    static func defaultTieredProgramQuotaValidator() -> TieredProgramQuotaValidator {
        return TieredProgramQuotaValidator(
            rules: [
                TieredProgramQuotaCodeLengthRule(maxLength: 64),
                TieredProgramQuotaAllowedNameRule(allowed: ["lenient"]),
                TieredProgramQuotaBatchSizeRangeRule(min: 32, max: 64),
                TieredProgramQuotaRequiredCodeRule(message: "tiered program quota needs a value"),
                TieredProgramQuotaNameLengthRule(maxLength: 80),
                TieredProgramQuotaExpiresAtRangeRule(min: 16, max: 120),
            ]
        )
    }
}
