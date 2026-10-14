import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a care gap plan must pass. Check returns its problems, or none.
    protocol CareGapPlanRule {
        func check(_ item: CareGapPlan) -> [String]
    }

    final class CareGapPlanBedLengthRule: CareGapPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareGapPlan) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareGapPlanRequiredBedRule: CareGapPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareGapPlan) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareGapPlanRequiredLabelRule: CareGapPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareGapPlan) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareGapPlanCodeLengthRule: CareGapPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareGapPlan) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a care gap plan.
    final class CareGapPlanValidator {
        var rules: [any CareGapPlanRule]

        init(rules: [any CareGapPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: CareGapPlan) -> [String] {
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

        func requireValid(_ item: CareGapPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareGapPlan]) -> [String: [String]] {
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

    static func defaultCareGapPlanValidator() -> CareGapPlanValidator {
        return CareGapPlanValidator(
            rules: [
                CareGapPlanBedLengthRule(maxLength: 80),
                CareGapPlanRequiredBedRule(message: "care gap plan needs an entry"),
                CareGapPlanRequiredLabelRule(message: "care gap plan needs an entry"),
                CareGapPlanCodeLengthRule(maxLength: 255),
            ]
        )
    }
}
