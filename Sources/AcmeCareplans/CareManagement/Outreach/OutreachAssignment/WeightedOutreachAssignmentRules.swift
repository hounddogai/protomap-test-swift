import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a weighted outreach assignment must pass. Check returns its problems, or none.
    protocol WeightedOutreachAssignmentRule {
        func check(_ item: WeightedOutreachAssignment) -> [String]
    }

    final class WeightedOutreachAssignmentCodeLengthRule: WeightedOutreachAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedOutreachAssignment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedOutreachAssignmentReviewerLengthRule: WeightedOutreachAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedOutreachAssignment) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedOutreachAssignmentVersionRangeRule: WeightedOutreachAssignmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedOutreachAssignment) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WeightedOutreachAssignmentEncounterIDLengthRule: WeightedOutreachAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedOutreachAssignment) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedOutreachAssignmentRequiredNameRule: WeightedOutreachAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedOutreachAssignment) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted outreach assignment.
    final class WeightedOutreachAssignmentValidator {
        var rules: [any WeightedOutreachAssignmentRule]

        init(rules: [any WeightedOutreachAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedOutreachAssignment) -> [String] {
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

        func requireValid(_ item: WeightedOutreachAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedOutreachAssignment]) -> [String: [String]] {
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

    static func defaultWeightedOutreachAssignmentValidator() -> WeightedOutreachAssignmentValidator {
        return WeightedOutreachAssignmentValidator(
            rules: [
                WeightedOutreachAssignmentCodeLengthRule(maxLength: 120),
                WeightedOutreachAssignmentReviewerLengthRule(maxLength: 32),
                WeightedOutreachAssignmentVersionRangeRule(min: 16, max: 3600),
                WeightedOutreachAssignmentEncounterIDLengthRule(maxLength: 64),
                WeightedOutreachAssignmentRequiredNameRule(message: "weighted outreach assignment needs an entry"),
            ]
        )
    }
}
