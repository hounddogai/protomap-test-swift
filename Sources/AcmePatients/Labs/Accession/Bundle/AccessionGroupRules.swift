import AcmePlatform
import Foundation

extension Labs {
    /// A rule a accession group must pass. Check returns its problems, or none.
    protocol AccessionGroupRule {
        func check(_ item: AccessionGroup) -> [String]
    }

    final class AccessionGroupAttemptsRangeRule: AccessionGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AccessionGroup) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AccessionGroupRevisionRangeRule: AccessionGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AccessionGroup) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AccessionGroupLabelLengthRule: AccessionGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AccessionGroup) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AccessionGroupRequiredCodeRule: AccessionGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AccessionGroup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a accession group.
    final class AccessionGroupValidator {
        var rules: [any AccessionGroupRule]

        init(rules: [any AccessionGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: AccessionGroup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AccessionGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AccessionGroup]) -> [String: [String]] {
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

    static func defaultAccessionGroupValidator() -> AccessionGroupValidator {
        return AccessionGroupValidator(
            rules: [
                AccessionGroupAttemptsRangeRule(min: 86400, max: 86400),
                AccessionGroupRevisionRangeRule(min: 16, max: 3600),
                AccessionGroupLabelLengthRule(maxLength: 120),
                AccessionGroupRequiredCodeRule(message: "accession group needs this field"),
            ]
        )
    }
}
