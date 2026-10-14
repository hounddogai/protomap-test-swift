import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a bed board profile must pass. Check returns its problems, or none.
    protocol BedBoardProfileRule {
        func check(_ item: BedBoardProfile) -> [String]
    }

    final class BedBoardProfileRequiredCategoryRule: BedBoardProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BedBoardProfile) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BedBoardProfileRequiredNameRule: BedBoardProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BedBoardProfile) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BedBoardProfileCreatedAtRangeRule: BedBoardProfileRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BedBoardProfile) -> [String] {
            let value = item.createdAt
            var problems: [String] = []
            if value < min {
                problems.append("created at \(value) is below \(min)")
            }
            if value > max {
                problems.append("created at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a bed board profile.
    final class BedBoardProfileValidator {
        var rules: [any BedBoardProfileRule]

        init(rules: [any BedBoardProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: BedBoardProfile) -> [String] {
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

        func requireValid(_ item: BedBoardProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BedBoardProfile]) -> [String: [String]] {
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

    static func defaultBedBoardProfileValidator() -> BedBoardProfileValidator {
        return BedBoardProfileValidator(
            rules: [
                BedBoardProfileRequiredCategoryRule(message: "bed board profile needs an entry"),
                BedBoardProfileRequiredNameRule(message: "bed board profile needs an entry"),
                BedBoardProfileCreatedAtRangeRule(min: 32, max: 3600),
            ]
        )
    }
}
