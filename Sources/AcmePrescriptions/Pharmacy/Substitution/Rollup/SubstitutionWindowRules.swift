import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a substitution window must pass. Check returns its problems, or none.
    protocol SubstitutionWindowRule {
        func check(_ item: SubstitutionWindow) -> [String]
    }

    final class SubstitutionWindowActiveGuardRule: SubstitutionWindowRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: SubstitutionWindow) -> [String] {
            if item.active && (item.quantity > limit) {
                return ["quantity \(item.quantity) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class SubstitutionWindowRequiredCodeRule: SubstitutionWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SubstitutionWindow) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SubstitutionWindowQuantityRangeRule: SubstitutionWindowRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SubstitutionWindow) -> [String] {
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

    final class SubstitutionWindowRequiredTitleRule: SubstitutionWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SubstitutionWindow) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SubstitutionWindowNameLengthRule: SubstitutionWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SubstitutionWindow) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a substitution window.
    final class SubstitutionWindowValidator {
        var rules: [any SubstitutionWindowRule]

        init(rules: [any SubstitutionWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: SubstitutionWindow) -> [String] {
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

        func requireValid(_ item: SubstitutionWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SubstitutionWindow]) -> [String: [String]] {
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

    static func defaultSubstitutionWindowValidator() -> SubstitutionWindowValidator {
        return SubstitutionWindowValidator(
            rules: [
                SubstitutionWindowActiveGuardRule(limit: 120),
                SubstitutionWindowRequiredCodeRule(message: "substitution window needs this field"),
                SubstitutionWindowQuantityRangeRule(min: 16, max: 86400),
                SubstitutionWindowRequiredTitleRule(message: "substitution window needs an entry"),
                SubstitutionWindowNameLengthRule(maxLength: 255),
            ]
        )
    }
}
