import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a acuity plan policy must pass. Check returns its problems, or none.
    protocol AcuityPlanPolicyRule {
        func check(_ item: AcuityPlanPolicy) -> [String]
    }

    final class AcuityPlanPolicySummaryLengthRule: AcuityPlanPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanPolicy) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AcuityPlanPolicyRequiredCodeRule: AcuityPlanPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AcuityPlanPolicy) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AcuityPlanPolicyCodeLengthRule: AcuityPlanPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanPolicy) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AcuityPlanPolicyBedLengthRule: AcuityPlanPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanPolicy) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AcuityPlanPolicyRequiredBedRule: AcuityPlanPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AcuityPlanPolicy) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AcuityPlanPolicyRatioRangeRule: AcuityPlanPolicyRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AcuityPlanPolicy) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a acuity plan policy.
    final class AcuityPlanPolicyValidator {
        var rules: [any AcuityPlanPolicyRule]

        init(rules: [any AcuityPlanPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: AcuityPlanPolicy) -> [String] {
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

        func requireValid(_ item: AcuityPlanPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AcuityPlanPolicy]) -> [String: [String]] {
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

    static func defaultAcuityPlanPolicyValidator() -> AcuityPlanPolicyValidator {
        return AcuityPlanPolicyValidator(
            rules: [
                AcuityPlanPolicySummaryLengthRule(maxLength: 120),
                AcuityPlanPolicyRequiredCodeRule(message: "acuity plan policy needs an entry"),
                AcuityPlanPolicyCodeLengthRule(maxLength: 16),
                AcuityPlanPolicyBedLengthRule(maxLength: 120),
                AcuityPlanPolicyRequiredBedRule(message: "acuity plan policy needs an entry"),
                AcuityPlanPolicyRatioRangeRule(min: 0.9, max: 1332.8),
            ]
        )
    }
}
