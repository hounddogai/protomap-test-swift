import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a tiered recall assignment must pass. Check returns its problems, or none.
    protocol TieredRecallAssignmentRule {
        func check(_ item: TieredRecallAssignment) -> [String]
    }

    final class TieredRecallAssignmentVersionRangeRule: TieredRecallAssignmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredRecallAssignment) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TieredRecallAssignmentRequiredCategoryRule: TieredRecallAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredRecallAssignment) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredRecallAssignmentRequiredClinicianIDRule: TieredRecallAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredRecallAssignment) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a tiered recall assignment.
    final class TieredRecallAssignmentValidator {
        var rules: [any TieredRecallAssignmentRule]

        init(rules: [any TieredRecallAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredRecallAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredRecallAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredRecallAssignment]) -> [String: [String]] {
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

    static func defaultTieredRecallAssignmentValidator() -> TieredRecallAssignmentValidator {
        return TieredRecallAssignmentValidator(
            rules: [
                TieredRecallAssignmentVersionRangeRule(min: 32, max: 80),
                TieredRecallAssignmentRequiredCategoryRule(message: "tiered recall assignment needs an entry"),
                TieredRecallAssignmentRequiredClinicianIDRule(message: "tiered recall assignment needs an entry"),
            ]
        )
    }
}
