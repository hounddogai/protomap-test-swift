import AcmePlatform
import Foundation

extension Labs {
    /// A rule a seasonal courier exception must pass. Check returns its problems, or none.
    protocol SeasonalCourierExceptionRule {
        func check(_ item: SeasonalCourierException) -> [String]
    }

    final class SeasonalCourierExceptionCodePrefixRule: SeasonalCourierExceptionRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SeasonalCourierException) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SeasonalCourierExceptionRequiredBedRule: SeasonalCourierExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalCourierException) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalCourierExceptionBedLengthRule: SeasonalCourierExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalCourierException) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalCourierExceptionTitleLengthRule: SeasonalCourierExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalCourierException) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal courier exception.
    final class SeasonalCourierExceptionValidator {
        var rules: [any SeasonalCourierExceptionRule]

        init(rules: [any SeasonalCourierExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalCourierException) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalCourierException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalCourierException]) -> [String: [String]] {
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

    static func defaultSeasonalCourierExceptionValidator() -> SeasonalCourierExceptionValidator {
        return SeasonalCourierExceptionValidator(
            rules: [
                SeasonalCourierExceptionCodePrefixRule(prefix: "OPS"),
                SeasonalCourierExceptionRequiredBedRule(message: "seasonal courier exception needs an entry"),
                SeasonalCourierExceptionBedLengthRule(maxLength: 80),
                SeasonalCourierExceptionTitleLengthRule(maxLength: 1000),
            ]
        )
    }
}
