import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a regional handoff quota must pass. Check returns its problems, or none.
    protocol RegionalHandoffQuotaRule {
        func check(_ item: RegionalHandoffQuota) -> [String]
    }

    final class RegionalHandoffQuotaMinimumRangeRule: RegionalHandoffQuotaRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalHandoffQuota) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RegionalHandoffQuotaRefillsRangeRule: RegionalHandoffQuotaRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalHandoffQuota) -> [String] {
            let value = item.refills
            var problems: [String] = []
            if value < min {
                problems.append("refills \(value) is below \(min)")
            }
            if value > max {
                problems.append("refills \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RegionalHandoffQuotaRequiredCodeRule: RegionalHandoffQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalHandoffQuota) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional handoff quota.
    final class RegionalHandoffQuotaValidator {
        var rules: [any RegionalHandoffQuotaRule]

        init(rules: [any RegionalHandoffQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalHandoffQuota) -> [String] {
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

        func requireValid(_ item: RegionalHandoffQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalHandoffQuota]) -> [String: [String]] {
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

    static func defaultRegionalHandoffQuotaValidator() -> RegionalHandoffQuotaValidator {
        return RegionalHandoffQuotaValidator(
            rules: [
                RegionalHandoffQuotaMinimumRangeRule(min: 3.0, max: 3590.4),
                RegionalHandoffQuotaRefillsRangeRule(min: 1000, max: 3600),
                RegionalHandoffQuotaRequiredCodeRule(message: "regional handoff quota needs a value"),
            ]
        )
    }
}
