import AcmePlatform
import Foundation

extension Consent {
    /// A rule a fallback revocation summary must pass. Check returns its problems, or none.
    protocol FallbackRevocationSummaryRule {
        func check(_ item: FallbackRevocationSummary) -> [String]
    }

    final class FallbackRevocationSummaryCodePrefixRule: FallbackRevocationSummaryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackRevocationSummary) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackRevocationSummaryTagsLimitRule: FallbackRevocationSummaryRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: FallbackRevocationSummary) -> [String] {
            var problems: [String] = []
            if item.tags.count > maxCount {
                problems.append("has \(item.tags.count) tags, at most \(maxCount) allowed")
            }
            for tag in item.tags {
                if banned.contains(tag) {
                    problems.append("tag \(tag) is not allowed")
                }
            }
            return problems
        }
    }

    final class FallbackRevocationSummaryRequiredLabelRule: FallbackRevocationSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackRevocationSummary) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackRevocationSummaryAllowedCodeRule: FallbackRevocationSummaryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackRevocationSummary) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is above maximum"]
            }
            return []
        }
    }

    final class FallbackRevocationSummaryDescriptionLengthRule: FallbackRevocationSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackRevocationSummary) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback revocation summary.
    final class FallbackRevocationSummaryValidator {
        var rules: [any FallbackRevocationSummaryRule]

        init(rules: [any FallbackRevocationSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackRevocationSummary) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackRevocationSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackRevocationSummary]) -> [String: [String]] {
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

    static func defaultFallbackRevocationSummaryValidator() -> FallbackRevocationSummaryValidator {
        return FallbackRevocationSummaryValidator(
            rules: [
                FallbackRevocationSummaryCodePrefixRule(prefix: "ACM"),
                FallbackRevocationSummaryTagsLimitRule(maxCount: 64, banned: ["weighted"]),
                FallbackRevocationSummaryRequiredLabelRule(message: "fallback revocation summary needs a value"),
                FallbackRevocationSummaryAllowedCodeRule(allowed: ["global"]),
                FallbackRevocationSummaryDescriptionLengthRule(maxLength: 32),
            ]
        )
    }
}
