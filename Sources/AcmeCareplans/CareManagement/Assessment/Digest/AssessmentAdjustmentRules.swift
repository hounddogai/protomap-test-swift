import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a assessment adjustment must pass. Check returns its problems, or none.
    protocol AssessmentAdjustmentRule {
        func check(_ item: AssessmentAdjustment) -> [String]
    }

    final class AssessmentAdjustmentCapacityRangeRule: AssessmentAdjustmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AssessmentAdjustment) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AssessmentAdjustmentRetriesRangeRule: AssessmentAdjustmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AssessmentAdjustment) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AssessmentAdjustmentEncounterIDLengthRule: AssessmentAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AssessmentAdjustment) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AssessmentAdjustmentCodeLengthRule: AssessmentAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AssessmentAdjustment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a assessment adjustment.
    final class AssessmentAdjustmentValidator {
        var rules: [any AssessmentAdjustmentRule]

        init(rules: [any AssessmentAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: AssessmentAdjustment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AssessmentAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AssessmentAdjustment]) -> [String: [String]] {
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

    static func defaultAssessmentAdjustmentValidator() -> AssessmentAdjustmentValidator {
        return AssessmentAdjustmentValidator(
            rules: [
                AssessmentAdjustmentCapacityRangeRule(min: 120, max: 3600),
                AssessmentAdjustmentRetriesRangeRule(min: 80, max: 3600),
                AssessmentAdjustmentEncounterIDLengthRule(maxLength: 16),
                AssessmentAdjustmentCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
