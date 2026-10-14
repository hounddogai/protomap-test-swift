import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a substitution group must pass. Check returns its problems, or none.
    protocol SubstitutionGroupRule {
        func check(_ item: SubstitutionGroup) -> [String]
    }

    final class SubstitutionGroupCodeLengthRule: SubstitutionGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SubstitutionGroup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SubstitutionGroupLimitRangeRule: SubstitutionGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SubstitutionGroup) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SubstitutionGroupExternalRefLengthRule: SubstitutionGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SubstitutionGroup) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SubstitutionGroupRequiredExternalRefRule: SubstitutionGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SubstitutionGroup) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SubstitutionGroupRequiredNameRule: SubstitutionGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SubstitutionGroup) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SubstitutionGroupCapacityRangeRule: SubstitutionGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SubstitutionGroup) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a substitution group.
    final class SubstitutionGroupValidator {
        var rules: [any SubstitutionGroupRule]

        init(rules: [any SubstitutionGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: SubstitutionGroup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SubstitutionGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SubstitutionGroup]) -> [String: [String]] {
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

    static func defaultSubstitutionGroupValidator() -> SubstitutionGroupValidator {
        return SubstitutionGroupValidator(
            rules: [
                SubstitutionGroupCodeLengthRule(maxLength: 86400),
                SubstitutionGroupLimitRangeRule(min: 32, max: 255),
                SubstitutionGroupExternalRefLengthRule(maxLength: 86400),
                SubstitutionGroupRequiredExternalRefRule(message: "substitution group needs this field"),
                SubstitutionGroupRequiredNameRule(message: "substitution group needs a value"),
                SubstitutionGroupCapacityRangeRule(min: 80, max: 1000),
            ]
        )
    }
}
