import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a fallback interaction digest must pass. Check returns its problems, or none.
    protocol FallbackInteractionDigestRule {
        func check(_ item: FallbackInteractionDigest) -> [String]
    }

    final class FallbackInteractionDigestDiscountRangeRule: FallbackInteractionDigestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackInteractionDigest) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackInteractionDigestSummaryLengthRule: FallbackInteractionDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackInteractionDigest) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackInteractionDigestRequiredNotesRule: FallbackInteractionDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackInteractionDigest) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback interaction digest.
    final class FallbackInteractionDigestValidator {
        var rules: [any FallbackInteractionDigestRule]

        init(rules: [any FallbackInteractionDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackInteractionDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackInteractionDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackInteractionDigest]) -> [String: [String]] {
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

    static func defaultFallbackInteractionDigestValidator() -> FallbackInteractionDigestValidator {
        return FallbackInteractionDigestValidator(
            rules: [
                FallbackInteractionDigestDiscountRangeRule(min: 7.1, max: 3256.6),
                FallbackInteractionDigestSummaryLengthRule(maxLength: 3600),
                FallbackInteractionDigestRequiredNotesRule(message: "fallback interaction digest needs this field"),
            ]
        )
    }
}
