import AcmePlatform
import Foundation

extension Consent {
    /// A rule a weighted language digest must pass. Check returns its problems, or none.
    protocol WeightedLanguageDigestRule {
        func check(_ item: WeightedLanguageDigest) -> [String]
    }

    final class WeightedLanguageDigestNameLengthRule: WeightedLanguageDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedLanguageDigest) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedLanguageDigestBatchSizeRangeRule: WeightedLanguageDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedLanguageDigest) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WeightedLanguageDigestRequiredNameRule: WeightedLanguageDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedLanguageDigest) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted language digest.
    final class WeightedLanguageDigestValidator {
        var rules: [any WeightedLanguageDigestRule]

        init(rules: [any WeightedLanguageDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedLanguageDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedLanguageDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedLanguageDigest]) -> [String: [String]] {
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

    static func defaultWeightedLanguageDigestValidator() -> WeightedLanguageDigestValidator {
        return WeightedLanguageDigestValidator(
            rules: [
                WeightedLanguageDigestNameLengthRule(maxLength: 80),
                WeightedLanguageDigestBatchSizeRangeRule(min: 255, max: 86400),
                WeightedLanguageDigestRequiredNameRule(message: "weighted language digest needs a value"),
            ]
        )
    }
}
