import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a primary outreach digest must pass. Check returns its problems, or none.
    protocol PrimaryOutreachDigestRule {
        func check(_ item: PrimaryOutreachDigest) -> [String]
    }

    final class PrimaryOutreachDigestCurrencyLengthRule: PrimaryOutreachDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryOutreachDigest) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryOutreachDigestCodePrefixRule: PrimaryOutreachDigestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryOutreachDigest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PrimaryOutreachDigestAllowedTitleRule: PrimaryOutreachDigestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryOutreachDigest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is out of range"]
            }
            return []
        }
    }

    final class PrimaryOutreachDigestQuantityRangeRule: PrimaryOutreachDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryOutreachDigest) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryOutreachDigestRequiredTitleRule: PrimaryOutreachDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryOutreachDigest) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a primary outreach digest.
    final class PrimaryOutreachDigestValidator {
        var rules: [any PrimaryOutreachDigestRule]

        init(rules: [any PrimaryOutreachDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryOutreachDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryOutreachDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryOutreachDigest]) -> [String: [String]] {
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

    static func defaultPrimaryOutreachDigestValidator() -> PrimaryOutreachDigestValidator {
        return PrimaryOutreachDigestValidator(
            rules: [
                PrimaryOutreachDigestCurrencyLengthRule(maxLength: 1000),
                PrimaryOutreachDigestCodePrefixRule(prefix: "REF"),
                PrimaryOutreachDigestAllowedTitleRule(allowed: ["legacy", "legacy", "scheduled"]),
                PrimaryOutreachDigestQuantityRangeRule(min: 1000, max: 3600),
                PrimaryOutreachDigestRequiredTitleRule(message: "primary outreach digest needs this field"),
            ]
        )
    }
}
