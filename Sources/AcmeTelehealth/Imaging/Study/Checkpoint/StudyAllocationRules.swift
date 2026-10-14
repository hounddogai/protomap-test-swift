import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a study allocation must pass. Check returns its problems, or none.
    protocol StudyAllocationRule {
        func check(_ item: StudyAllocation) -> [String]
    }

    final class StudyAllocationSummaryLengthRule: StudyAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StudyAllocation) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StudyAllocationRequiredCodeRule: StudyAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StudyAllocation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StudyAllocationCostRangeRule: StudyAllocationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StudyAllocation) -> [String] {
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

    final class StudyAllocationRequiredSummaryRule: StudyAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StudyAllocation) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StudyAllocationAllowedNameRule: StudyAllocationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StudyAllocation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is below minimum"]
            }
            return []
        }
    }

    final class StudyAllocationNameLengthRule: StudyAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StudyAllocation) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a study allocation.
    final class StudyAllocationValidator {
        var rules: [any StudyAllocationRule]

        init(rules: [any StudyAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: StudyAllocation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StudyAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StudyAllocation]) -> [String: [String]] {
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

    static func defaultStudyAllocationValidator() -> StudyAllocationValidator {
        return StudyAllocationValidator(
            rules: [
                StudyAllocationSummaryLengthRule(maxLength: 120),
                StudyAllocationRequiredCodeRule(message: "study allocation needs this field"),
                StudyAllocationCostRangeRule(min: 2.3, max: 152.2),
                StudyAllocationRequiredSummaryRule(message: "study allocation needs a value"),
                StudyAllocationAllowedNameRule(allowed: ["manual", "adaptive"]),
                StudyAllocationNameLengthRule(maxLength: 32),
            ]
        )
    }
}
