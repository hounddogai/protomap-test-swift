import AcmePlatform
import Foundation

extension Labs {
    /// A rule a accession plan must pass. Check returns its problems, or none.
    protocol AccessionPlanRule {
        func check(_ item: AccessionPlan) -> [String]
    }

    final class AccessionPlanRequiredDiagnosisCodeRule: AccessionPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AccessionPlan) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AccessionPlanCodeLengthRule: AccessionPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AccessionPlan) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AccessionPlanTitleLengthRule: AccessionPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AccessionPlan) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AccessionPlanRequiredTimezoneRule: AccessionPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AccessionPlan) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AccessionPlanTimezoneLengthRule: AccessionPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AccessionPlan) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a accession plan.
    final class AccessionPlanValidator {
        var rules: [any AccessionPlanRule]

        init(rules: [any AccessionPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: AccessionPlan) -> [String] {
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

        func requireValid(_ item: AccessionPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AccessionPlan]) -> [String: [String]] {
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

    static func defaultAccessionPlanValidator() -> AccessionPlanValidator {
        return AccessionPlanValidator(
            rules: [
                AccessionPlanRequiredDiagnosisCodeRule(message: "accession plan needs this field"),
                AccessionPlanCodeLengthRule(maxLength: 120),
                AccessionPlanTitleLengthRule(maxLength: 255),
                AccessionPlanRequiredTimezoneRule(message: "accession plan needs an entry"),
                AccessionPlanTimezoneLengthRule(maxLength: 64),
            ]
        )
    }
}
