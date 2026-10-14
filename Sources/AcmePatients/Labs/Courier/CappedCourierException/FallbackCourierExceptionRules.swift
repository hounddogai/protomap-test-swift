import AcmePlatform
import Foundation

extension Labs {
    /// A rule a fallback courier exception must pass. Check returns its problems, or none.
    protocol FallbackCourierExceptionRule {
        func check(_ item: FallbackCourierException) -> [String]
    }

    final class FallbackCourierExceptionRequiredNameRule: FallbackCourierExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackCourierException) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackCourierExceptionRequiredCodeRule: FallbackCourierExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackCourierException) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackCourierExceptionTitleLengthRule: FallbackCourierExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackCourierException) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback courier exception.
    final class FallbackCourierExceptionValidator {
        var rules: [any FallbackCourierExceptionRule]

        init(rules: [any FallbackCourierExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackCourierException) -> [String] {
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

        func requireValid(_ item: FallbackCourierException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackCourierException]) -> [String: [String]] {
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

    static func defaultFallbackCourierExceptionValidator() -> FallbackCourierExceptionValidator {
        return FallbackCourierExceptionValidator(
            rules: [
                FallbackCourierExceptionRequiredNameRule(message: "fallback courier exception needs a value"),
                FallbackCourierExceptionRequiredCodeRule(message: "fallback courier exception needs an entry"),
                FallbackCourierExceptionTitleLengthRule(maxLength: 255),
            ]
        )
    }
}
