import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a assessment quota must pass. Check returns its problems, or none.
    protocol AssessmentQuotaRule {
        func check(_ item: AssessmentQuota) -> [String]
    }

    final class AssessmentQuotaCodeLengthRule: AssessmentQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AssessmentQuota) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AssessmentQuotaWeightRangeRule: AssessmentQuotaRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AssessmentQuota) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AssessmentQuotaRequiredCodeRule: AssessmentQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AssessmentQuota) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AssessmentQuotaNameLengthRule: AssessmentQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AssessmentQuota) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AssessmentQuotaWardLengthRule: AssessmentQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AssessmentQuota) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AssessmentQuotaRequiredWardRule: AssessmentQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AssessmentQuota) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a assessment quota.
    final class AssessmentQuotaValidator {
        var rules: [any AssessmentQuotaRule]

        init(rules: [any AssessmentQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: AssessmentQuota) -> [String] {
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

        func requireValid(_ item: AssessmentQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AssessmentQuota]) -> [String: [String]] {
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

    static func defaultAssessmentQuotaValidator() -> AssessmentQuotaValidator {
        return AssessmentQuotaValidator(
            rules: [
                AssessmentQuotaCodeLengthRule(maxLength: 80),
                AssessmentQuotaWeightRangeRule(min: 0.1, max: 3843.1),
                AssessmentQuotaRequiredCodeRule(message: "assessment quota needs an entry"),
                AssessmentQuotaNameLengthRule(maxLength: 255),
                AssessmentQuotaWardLengthRule(maxLength: 255),
                AssessmentQuotaRequiredWardRule(message: "assessment quota needs an entry"),
            ]
        )
    }
}
