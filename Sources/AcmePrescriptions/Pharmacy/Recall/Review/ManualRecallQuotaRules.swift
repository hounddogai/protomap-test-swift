import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a manual recall quota must pass. Check returns its problems, or none.
    protocol ManualRecallQuotaRule {
        func check(_ item: ManualRecallQuota) -> [String]
    }

    final class ManualRecallQuotaRequiredLabelRule: ManualRecallQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualRecallQuota) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualRecallQuotaRequiredSourceRule: ManualRecallQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualRecallQuota) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualRecallQuotaLabelLengthRule: ManualRecallQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualRecallQuota) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualRecallQuotaProcedureCodeLengthRule: ManualRecallQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualRecallQuota) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualRecallQuotaAcuityRangeRule: ManualRecallQuotaRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualRecallQuota) -> [String] {
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

    final class ManualRecallQuotaRatioRangeRule: ManualRecallQuotaRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualRecallQuota) -> [String] {
            let value = item.ratio
            var problems: [String] = []
            if value < min {
                problems.append("ratio \(value) is below \(min)")
            }
            if value > max {
                problems.append("ratio \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a manual recall quota.
    final class ManualRecallQuotaValidator {
        var rules: [any ManualRecallQuotaRule]

        init(rules: [any ManualRecallQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualRecallQuota) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualRecallQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualRecallQuota]) -> [String: [String]] {
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

    static func defaultManualRecallQuotaValidator() -> ManualRecallQuotaValidator {
        return ManualRecallQuotaValidator(
            rules: [
                ManualRecallQuotaRequiredLabelRule(message: "manual recall quota needs this field"),
                ManualRecallQuotaRequiredSourceRule(message: "manual recall quota needs an entry"),
                ManualRecallQuotaLabelLengthRule(maxLength: 86400),
                ManualRecallQuotaProcedureCodeLengthRule(maxLength: 120),
                ManualRecallQuotaAcuityRangeRule(min: 80, max: 80),
                ManualRecallQuotaRatioRangeRule(min: 7.4, max: 734.2),
            ]
        )
    }
}
