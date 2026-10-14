import AcmePlatform
import Foundation

extension Labs {
    /// A rule a fallback specimen tier must pass. Check returns its problems, or none.
    protocol FallbackSpecimenTierRule {
        func check(_ item: FallbackSpecimenTier) -> [String]
    }

    final class FallbackSpecimenTierReviewerLengthRule: FallbackSpecimenTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackSpecimenTier) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackSpecimenTierCodePrefixRule: FallbackSpecimenTierRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackSpecimenTier) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackSpecimenTierRequiredCodeRule: FallbackSpecimenTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackSpecimenTier) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback specimen tier.
    final class FallbackSpecimenTierValidator {
        var rules: [any FallbackSpecimenTierRule]

        init(rules: [any FallbackSpecimenTierRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackSpecimenTier) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackSpecimenTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackSpecimenTier]) -> [String: [String]] {
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

    static func defaultFallbackSpecimenTierValidator() -> FallbackSpecimenTierValidator {
        return FallbackSpecimenTierValidator(
            rules: [
                FallbackSpecimenTierReviewerLengthRule(maxLength: 255),
                FallbackSpecimenTierCodePrefixRule(prefix: "ACM"),
                FallbackSpecimenTierRequiredCodeRule(message: "fallback specimen tier needs an entry"),
            ]
        )
    }
}
