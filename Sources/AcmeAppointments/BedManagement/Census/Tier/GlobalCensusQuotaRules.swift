import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a global census quota must pass. Check returns its problems, or none.
    protocol GlobalCensusQuotaRule {
        func check(_ item: GlobalCensusQuota) -> [String]
    }

    final class GlobalCensusQuotaRequiredCodeRule: GlobalCensusQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalCensusQuota) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalCensusQuotaCodeLengthRule: GlobalCensusQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalCensusQuota) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalCensusQuotaAmountRangeRule: GlobalCensusQuotaRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalCensusQuota) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalCensusQuotaWardLengthRule: GlobalCensusQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalCensusQuota) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global census quota.
    final class GlobalCensusQuotaValidator {
        var rules: [any GlobalCensusQuotaRule]

        init(rules: [any GlobalCensusQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalCensusQuota) -> [String] {
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

        func requireValid(_ item: GlobalCensusQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalCensusQuota]) -> [String: [String]] {
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

    static func defaultGlobalCensusQuotaValidator() -> GlobalCensusQuotaValidator {
        return GlobalCensusQuotaValidator(
            rules: [
                GlobalCensusQuotaRequiredCodeRule(message: "global census quota needs an entry"),
                GlobalCensusQuotaCodeLengthRule(maxLength: 1000),
                GlobalCensusQuotaAmountRangeRule(min: 8.2, max: 1557.9),
                GlobalCensusQuotaWardLengthRule(maxLength: 120),
            ]
        )
    }
}
