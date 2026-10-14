import AcmePlatform
import Foundation

extension Labs {
    /// A rule a result bundle must pass. Check returns its problems, or none.
    protocol ResultBundleRule {
        func check(_ item: ResultBundle) -> [String]
    }

    final class ResultBundleRequiredCurrencyRule: ResultBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ResultBundle) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ResultBundleVersionRangeRule: ResultBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ResultBundle) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ResultBundleRequiredTitleRule: ResultBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ResultBundle) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ResultBundleAllergyLengthRule: ResultBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ResultBundle) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a result bundle.
    final class ResultBundleValidator {
        var rules: [any ResultBundleRule]

        init(rules: [any ResultBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: ResultBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ResultBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ResultBundle]) -> [String: [String]] {
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

    static func defaultResultBundleValidator() -> ResultBundleValidator {
        return ResultBundleValidator(
            rules: [
                ResultBundleRequiredCurrencyRule(message: "result bundle needs an entry"),
                ResultBundleVersionRangeRule(min: 86400, max: 86400),
                ResultBundleRequiredTitleRule(message: "result bundle needs a value"),
                ResultBundleAllergyLengthRule(maxLength: 120),
            ]
        )
    }
}
