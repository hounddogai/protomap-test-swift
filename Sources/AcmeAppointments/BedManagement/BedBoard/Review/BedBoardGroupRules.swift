import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a bed board group must pass. Check returns its problems, or none.
    protocol BedBoardGroupRule {
        func check(_ item: BedBoardGroup) -> [String]
    }

    final class BedBoardGroupStartsAtRangeRule: BedBoardGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BedBoardGroup) -> [String] {
            let value = item.startsAt
            var problems: [String] = []
            if value < min {
                problems.append("starts at \(value) is below \(min)")
            }
            if value > max {
                problems.append("starts at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BedBoardGroupCodeLengthRule: BedBoardGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BedBoardGroup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BedBoardGroupRequiredNameRule: BedBoardGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BedBoardGroup) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BedBoardGroupNameLengthRule: BedBoardGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BedBoardGroup) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BedBoardGroupRequiredTitleRule: BedBoardGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BedBoardGroup) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a bed board group.
    final class BedBoardGroupValidator {
        var rules: [any BedBoardGroupRule]

        init(rules: [any BedBoardGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: BedBoardGroup) -> [String] {
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

        func requireValid(_ item: BedBoardGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BedBoardGroup]) -> [String: [String]] {
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

    static func defaultBedBoardGroupValidator() -> BedBoardGroupValidator {
        return BedBoardGroupValidator(
            rules: [
                BedBoardGroupStartsAtRangeRule(min: 80, max: 120),
                BedBoardGroupCodeLengthRule(maxLength: 86400),
                BedBoardGroupRequiredNameRule(message: "bed board group needs an entry"),
                BedBoardGroupNameLengthRule(maxLength: 32),
                BedBoardGroupRequiredTitleRule(message: "bed board group needs this field"),
            ]
        )
    }
}
