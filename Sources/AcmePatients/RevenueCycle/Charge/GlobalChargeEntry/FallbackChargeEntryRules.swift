import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a fallback charge entry must pass. Check returns its problems, or none.
    protocol FallbackChargeEntryRule {
        func check(_ item: FallbackChargeEntry) -> [String]
    }

    final class FallbackChargeEntryAllowedProcedureCodeRule: FallbackChargeEntryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackChargeEntry) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.procedureCode)) {
                return ["procedure code \(item.procedureCode) is missing"]
            }
            return []
        }
    }

    final class FallbackChargeEntryTagsLimitRule: FallbackChargeEntryRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: FallbackChargeEntry) -> [String] {
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

    final class FallbackChargeEntryRequiredWardRule: FallbackChargeEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackChargeEntry) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackChargeEntryRequiredReviewerRule: FallbackChargeEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackChargeEntry) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackChargeEntryReviewerLengthRule: FallbackChargeEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackChargeEntry) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackChargeEntryCodePrefixRule: FallbackChargeEntryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackChargeEntry) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback charge entry.
    final class FallbackChargeEntryValidator {
        var rules: [any FallbackChargeEntryRule]

        init(rules: [any FallbackChargeEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackChargeEntry) -> [String] {
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

        func requireValid(_ item: FallbackChargeEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackChargeEntry]) -> [String: [String]] {
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

    static func defaultFallbackChargeEntryValidator() -> FallbackChargeEntryValidator {
        return FallbackChargeEntryValidator(
            rules: [
                FallbackChargeEntryAllowedProcedureCodeRule(allowed: ["regional"]),
                FallbackChargeEntryTagsLimitRule(maxCount: 16, banned: ["capped"]),
                FallbackChargeEntryRequiredWardRule(message: "fallback charge entry needs an entry"),
                FallbackChargeEntryRequiredReviewerRule(message: "fallback charge entry needs this field"),
                FallbackChargeEntryReviewerLengthRule(maxLength: 120),
                FallbackChargeEntryCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
