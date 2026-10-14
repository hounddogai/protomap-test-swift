import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a seasonal worklist assignment must pass. Check returns its problems, or none.
    protocol SeasonalWorklistAssignmentRule {
        func check(_ item: SeasonalWorklistAssignment) -> [String]
    }

    final class SeasonalWorklistAssignmentPinnedGuardRule: SeasonalWorklistAssignmentRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: SeasonalWorklistAssignment) -> [String] {
            if item.pinned && (item.quantity > limit) {
                return ["quantity \(item.quantity) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class SeasonalWorklistAssignmentCodeLengthRule: SeasonalWorklistAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalWorklistAssignment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalWorklistAssignmentQuantityRangeRule: SeasonalWorklistAssignmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalWorklistAssignment) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SeasonalWorklistAssignmentRequiredLabelRule: SeasonalWorklistAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalWorklistAssignment) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal worklist assignment.
    final class SeasonalWorklistAssignmentValidator {
        var rules: [any SeasonalWorklistAssignmentRule]

        init(rules: [any SeasonalWorklistAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalWorklistAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalWorklistAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalWorklistAssignment]) -> [String: [String]] {
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

    static func defaultSeasonalWorklistAssignmentValidator() -> SeasonalWorklistAssignmentValidator {
        return SeasonalWorklistAssignmentValidator(
            rules: [
                SeasonalWorklistAssignmentPinnedGuardRule(limit: 80),
                SeasonalWorklistAssignmentCodeLengthRule(maxLength: 3600),
                SeasonalWorklistAssignmentQuantityRangeRule(min: 64, max: 255),
                SeasonalWorklistAssignmentRequiredLabelRule(message: "seasonal worklist assignment needs an entry"),
            ]
        )
    }
}
