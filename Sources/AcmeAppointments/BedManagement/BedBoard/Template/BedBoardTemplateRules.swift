import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a bed board template must pass. Check returns its problems, or none.
    protocol BedBoardTemplateRule {
        func check(_ item: BedBoardTemplate) -> [String]
    }

    final class BedBoardTemplateWeightRangeRule: BedBoardTemplateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BedBoardTemplate) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BedBoardTemplateActiveGuardRule: BedBoardTemplateRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: BedBoardTemplate) -> [String] {
            if item.active && (item.createdAt > limit) {
                return ["created at \(item.createdAt) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class BedBoardTemplateRequiredTitleRule: BedBoardTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BedBoardTemplate) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BedBoardTemplateRequiredCodeRule: BedBoardTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BedBoardTemplate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BedBoardTemplateWardLengthRule: BedBoardTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BedBoardTemplate) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BedBoardTemplateCreatedAtRangeRule: BedBoardTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BedBoardTemplate) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a bed board template.
    final class BedBoardTemplateValidator {
        var rules: [any BedBoardTemplateRule]

        init(rules: [any BedBoardTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: BedBoardTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BedBoardTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BedBoardTemplate]) -> [String: [String]] {
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

    static func defaultBedBoardTemplateValidator() -> BedBoardTemplateValidator {
        return BedBoardTemplateValidator(
            rules: [
                BedBoardTemplateWeightRangeRule(min: 5.6, max: 2206.6),
                BedBoardTemplateActiveGuardRule(limit: 16),
                BedBoardTemplateRequiredTitleRule(message: "bed board template needs a value"),
                BedBoardTemplateRequiredCodeRule(message: "bed board template needs an entry"),
                BedBoardTemplateWardLengthRule(maxLength: 32),
                BedBoardTemplateCreatedAtRangeRule(min: 64, max: 80),
            ]
        )
    }
}
