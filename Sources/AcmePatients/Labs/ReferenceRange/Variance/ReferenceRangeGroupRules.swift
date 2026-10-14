import AcmePlatform
import Foundation

extension Labs {
    /// A rule a reference range group must pass. Check returns its problems, or none.
    protocol ReferenceRangeGroupRule {
        func check(_ item: ReferenceRangeGroup) -> [String]
    }

    final class ReferenceRangeGroupRequiredCodeRule: ReferenceRangeGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferenceRangeGroup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferenceRangeGroupNameLengthRule: ReferenceRangeGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferenceRangeGroup) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferenceRangeGroupStartsAtRangeRule: ReferenceRangeGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferenceRangeGroup) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ReferenceRangeGroupRequiredLabelRule: ReferenceRangeGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferenceRangeGroup) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a reference range group.
    final class ReferenceRangeGroupValidator {
        var rules: [any ReferenceRangeGroupRule]

        init(rules: [any ReferenceRangeGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferenceRangeGroup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReferenceRangeGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferenceRangeGroup]) -> [String: [String]] {
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

    static func defaultReferenceRangeGroupValidator() -> ReferenceRangeGroupValidator {
        return ReferenceRangeGroupValidator(
            rules: [
                ReferenceRangeGroupRequiredCodeRule(message: "reference range group needs a value"),
                ReferenceRangeGroupNameLengthRule(maxLength: 1000),
                ReferenceRangeGroupStartsAtRangeRule(min: 80, max: 3600),
                ReferenceRangeGroupRequiredLabelRule(message: "reference range group needs this field"),
            ]
        )
    }
}
