import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a study agreement must pass. Check returns its problems, or none.
    protocol StudyAgreementRule {
        func check(_ item: StudyAgreement) -> [String]
    }

    final class StudyAgreementRequiredTitleRule: StudyAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StudyAgreement) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StudyAgreementCostRangeRule: StudyAgreementRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StudyAgreement) -> [String] {
            let value = item.cost
            var problems: [String] = []
            if value < min {
                problems.append("cost \(value) is below \(min)")
            }
            if value > max {
                problems.append("cost \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StudyAgreementCodeLengthRule: StudyAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StudyAgreement) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StudyAgreementAllowedCategoryRule: StudyAgreementRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StudyAgreement) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.category)) {
                return ["category \(item.category) is blocked"]
            }
            return []
        }
    }

    /// Runs every rule of a study agreement.
    final class StudyAgreementValidator {
        var rules: [any StudyAgreementRule]

        init(rules: [any StudyAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: StudyAgreement) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StudyAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StudyAgreement]) -> [String: [String]] {
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

    static func defaultStudyAgreementValidator() -> StudyAgreementValidator {
        return StudyAgreementValidator(
            rules: [
                StudyAgreementRequiredTitleRule(message: "study agreement needs a value"),
                StudyAgreementCostRangeRule(min: 5.9, max: 3755.6),
                StudyAgreementCodeLengthRule(maxLength: 255),
                StudyAgreementAllowedCategoryRule(allowed: ["lenient"]),
            ]
        )
    }
}
