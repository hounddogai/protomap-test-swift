import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a legacy task mapping must pass. Check returns its problems, or none.
    protocol LegacyTaskMappingRule {
        func check(_ item: LegacyTaskMapping) -> [String]
    }

    final class LegacyTaskMappingCodeLengthRule: LegacyTaskMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyTaskMapping) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyTaskMappingBudgetRangeRule: LegacyTaskMappingRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyTaskMapping) -> [String] {
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

    final class LegacyTaskMappingPatientRefLengthRule: LegacyTaskMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyTaskMapping) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy task mapping.
    final class LegacyTaskMappingValidator {
        var rules: [any LegacyTaskMappingRule]

        init(rules: [any LegacyTaskMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyTaskMapping) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyTaskMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyTaskMapping]) -> [String: [String]] {
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

    static func defaultLegacyTaskMappingValidator() -> LegacyTaskMappingValidator {
        return LegacyTaskMappingValidator(
            rules: [
                LegacyTaskMappingCodeLengthRule(maxLength: 16),
                LegacyTaskMappingBudgetRangeRule(min: 1.0, max: 2534.7),
                LegacyTaskMappingPatientRefLengthRule(maxLength: 80),
            ]
        )
    }
}
