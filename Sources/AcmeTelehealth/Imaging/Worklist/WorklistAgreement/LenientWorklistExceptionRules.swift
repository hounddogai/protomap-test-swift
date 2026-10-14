import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a lenient worklist exception must pass. Check returns its problems, or none.
    protocol LenientWorklistExceptionRule {
        func check(_ item: LenientWorklistException) -> [String]
    }

    final class LenientWorklistExceptionDescriptionLengthRule: LenientWorklistExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientWorklistException) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientWorklistExceptionTitleLengthRule: LenientWorklistExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientWorklistException) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientWorklistExceptionRequiredDescriptionRule: LenientWorklistExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientWorklistException) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientWorklistExceptionRevisionRangeRule: LenientWorklistExceptionRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientWorklistException) -> [String] {
            let value = item.revision
            var problems: [String] = []
            if value < min {
                problems.append("revision \(value) is below \(min)")
            }
            if value > max {
                problems.append("revision \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a lenient worklist exception.
    final class LenientWorklistExceptionValidator {
        var rules: [any LenientWorklistExceptionRule]

        init(rules: [any LenientWorklistExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientWorklistException) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientWorklistException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientWorklistException]) -> [String: [String]] {
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

    static func defaultLenientWorklistExceptionValidator() -> LenientWorklistExceptionValidator {
        return LenientWorklistExceptionValidator(
            rules: [
                LenientWorklistExceptionDescriptionLengthRule(maxLength: 3600),
                LenientWorklistExceptionTitleLengthRule(maxLength: 3600),
                LenientWorklistExceptionRequiredDescriptionRule(message: "lenient worklist exception needs an entry"),
                LenientWorklistExceptionRevisionRangeRule(min: 120, max: 1000),
            ]
        )
    }
}
