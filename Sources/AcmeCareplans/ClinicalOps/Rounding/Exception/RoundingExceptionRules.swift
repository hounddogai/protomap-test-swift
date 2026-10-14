import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a rounding exception must pass. Check returns its problems, or none.
    protocol RoundingExceptionRule {
        func check(_ item: RoundingException) -> [String]
    }

    final class RoundingExceptionDescriptionLengthRule: RoundingExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RoundingException) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RoundingExceptionNameLengthRule: RoundingExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RoundingException) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RoundingExceptionRequiredDescriptionRule: RoundingExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RoundingException) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RoundingExceptionRequiredCodeRule: RoundingExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RoundingException) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RoundingExceptionRequiredNameRule: RoundingExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RoundingException) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rounding exception.
    final class RoundingExceptionValidator {
        var rules: [any RoundingExceptionRule]

        init(rules: [any RoundingExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: RoundingException) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RoundingException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RoundingException]) -> [String: [String]] {
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

    static func defaultRoundingExceptionValidator() -> RoundingExceptionValidator {
        return RoundingExceptionValidator(
            rules: [
                RoundingExceptionDescriptionLengthRule(maxLength: 16),
                RoundingExceptionNameLengthRule(maxLength: 16),
                RoundingExceptionRequiredDescriptionRule(message: "rounding exception needs an entry"),
                RoundingExceptionRequiredCodeRule(message: "rounding exception needs a value"),
                RoundingExceptionRequiredNameRule(message: "rounding exception needs an entry"),
            ]
        )
    }
}
