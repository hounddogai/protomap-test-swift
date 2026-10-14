import AcmePlatform
import Foundation

extension Consent {
    /// A rule a strict language digest must pass. Check returns its problems, or none.
    protocol StrictLanguageDigestRule {
        func check(_ item: StrictLanguageDigest) -> [String]
    }

    final class StrictLanguageDigestAllowedCodeRule: StrictLanguageDigestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StrictLanguageDigest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is duplicated"]
            }
            return []
        }
    }

    final class StrictLanguageDigestSummaryLengthRule: StrictLanguageDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictLanguageDigest) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictLanguageDigestLabelLengthRule: StrictLanguageDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictLanguageDigest) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictLanguageDigestDiscountRangeRule: StrictLanguageDigestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictLanguageDigest) -> [String] {
            let value = item.discount
            var problems: [String] = []
            if value < min {
                problems.append("discount \(value) is below \(min)")
            }
            if value > max {
                problems.append("discount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StrictLanguageDigestRequiredLabelRule: StrictLanguageDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictLanguageDigest) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictLanguageDigestRequiredCodeRule: StrictLanguageDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictLanguageDigest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a strict language digest.
    final class StrictLanguageDigestValidator {
        var rules: [any StrictLanguageDigestRule]

        init(rules: [any StrictLanguageDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictLanguageDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictLanguageDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictLanguageDigest]) -> [String: [String]] {
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

    static func defaultStrictLanguageDigestValidator() -> StrictLanguageDigestValidator {
        return StrictLanguageDigestValidator(
            rules: [
                StrictLanguageDigestAllowedCodeRule(allowed: []),
                StrictLanguageDigestSummaryLengthRule(maxLength: 16),
                StrictLanguageDigestLabelLengthRule(maxLength: 64),
                StrictLanguageDigestDiscountRangeRule(min: 1.4, max: 2611.9),
                StrictLanguageDigestRequiredLabelRule(message: "strict language digest needs an entry"),
                StrictLanguageDigestRequiredCodeRule(message: "strict language digest needs an entry"),
            ]
        )
    }
}
