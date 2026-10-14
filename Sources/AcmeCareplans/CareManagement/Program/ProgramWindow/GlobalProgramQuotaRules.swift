import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a global program quota must pass. Check returns its problems, or none.
    protocol GlobalProgramQuotaRule {
        func check(_ item: GlobalProgramQuota) -> [String]
    }

    final class GlobalProgramQuotaCodePrefixRule: GlobalProgramQuotaRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalProgramQuota) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GlobalProgramQuotaRequiredCodeRule: GlobalProgramQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalProgramQuota) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalProgramQuotaDosageMgRangeRule: GlobalProgramQuotaRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalProgramQuota) -> [String] {
            let value = item.dosageMg
            var problems: [String] = []
            if value < min {
                problems.append("dosage mg \(value) is below \(min)")
            }
            if value > max {
                problems.append("dosage mg \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a global program quota.
    final class GlobalProgramQuotaValidator {
        var rules: [any GlobalProgramQuotaRule]

        init(rules: [any GlobalProgramQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalProgramQuota) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalProgramQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalProgramQuota]) -> [String: [String]] {
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

    static func defaultGlobalProgramQuotaValidator() -> GlobalProgramQuotaValidator {
        return GlobalProgramQuotaValidator(
            rules: [
                GlobalProgramQuotaCodePrefixRule(prefix: "REF"),
                GlobalProgramQuotaRequiredCodeRule(message: "global program quota needs a value"),
                GlobalProgramQuotaDosageMgRangeRule(min: 1.1, max: 674.1),
            ]
        )
    }
}
