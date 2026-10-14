import AcmePlatform
import Foundation

extension Consent {
    /// A rule a disclosure digest must pass. Check returns its problems, or none.
    protocol DisclosureDigestRule {
        func check(_ item: DisclosureDigest) -> [String]
    }

    final class DisclosureDigestApprovedGuardRule: DisclosureDigestRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: DisclosureDigest) -> [String] {
            if item.approved && (item.rate > limit) {
                return ["rate \(item.rate) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class DisclosureDigestCodePrefixRule: DisclosureDigestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DisclosureDigest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DisclosureDigestTitleLengthRule: DisclosureDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DisclosureDigest) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DisclosureDigestAllowedLabelRule: DisclosureDigestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DisclosureDigest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is unknown"]
            }
            return []
        }
    }

    final class DisclosureDigestRequiredTitleRule: DisclosureDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosureDigest) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a disclosure digest.
    final class DisclosureDigestValidator {
        var rules: [any DisclosureDigestRule]

        init(rules: [any DisclosureDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: DisclosureDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DisclosureDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DisclosureDigest]) -> [String: [String]] {
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

    static func defaultDisclosureDigestValidator() -> DisclosureDigestValidator {
        return DisclosureDigestValidator(
            rules: [
                DisclosureDigestApprovedGuardRule(limit: 8.8),
                DisclosureDigestCodePrefixRule(prefix: "Q"),
                DisclosureDigestTitleLengthRule(maxLength: 86400),
                DisclosureDigestAllowedLabelRule(allowed: ["default", "pending", "strict"]),
                DisclosureDigestRequiredTitleRule(message: "disclosure digest needs a value"),
            ]
        )
    }
}
