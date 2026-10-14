import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a discharge plan quota must pass. Check returns its problems, or none.
    protocol DischargePlanQuotaRule {
        func check(_ item: DischargePlanQuota) -> [String]
    }

    final class DischargePlanQuotaBudgetRangeRule: DischargePlanQuotaRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DischargePlanQuota) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DischargePlanQuotaRequiredCodeRule: DischargePlanQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DischargePlanQuota) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DischargePlanQuotaLabelLengthRule: DischargePlanQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DischargePlanQuota) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a discharge plan quota.
    final class DischargePlanQuotaValidator {
        var rules: [any DischargePlanQuotaRule]

        init(rules: [any DischargePlanQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: DischargePlanQuota) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DischargePlanQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DischargePlanQuota]) -> [String: [String]] {
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

    static func defaultDischargePlanQuotaValidator() -> DischargePlanQuotaValidator {
        return DischargePlanQuotaValidator(
            rules: [
                DischargePlanQuotaBudgetRangeRule(min: 0.9, max: 1644.5),
                DischargePlanQuotaRequiredCodeRule(message: "discharge plan quota needs this field"),
                DischargePlanQuotaLabelLengthRule(maxLength: 255),
            ]
        )
    }
}
