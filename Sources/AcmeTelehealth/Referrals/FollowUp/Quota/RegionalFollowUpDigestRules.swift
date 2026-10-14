import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a regional follow up digest must pass. Check returns its problems, or none.
    protocol RegionalFollowUpDigestRule {
        func check(_ item: RegionalFollowUpDigest) -> [String]
    }

    final class RegionalFollowUpDigestRateRangeRule: RegionalFollowUpDigestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalFollowUpDigest) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalFollowUpDigestRequiredCodeRule: RegionalFollowUpDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalFollowUpDigest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalFollowUpDigestCodePrefixRule: RegionalFollowUpDigestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalFollowUpDigest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional follow up digest.
    final class RegionalFollowUpDigestValidator {
        var rules: [any RegionalFollowUpDigestRule]

        init(rules: [any RegionalFollowUpDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalFollowUpDigest) -> [String] {
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

        func requireValid(_ item: RegionalFollowUpDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalFollowUpDigest]) -> [String: [String]] {
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

    static func defaultRegionalFollowUpDigestValidator() -> RegionalFollowUpDigestValidator {
        return RegionalFollowUpDigestValidator(
            rules: [
                RegionalFollowUpDigestRateRangeRule(min: 6.9, max: 500.6),
                RegionalFollowUpDigestRequiredCodeRule(message: "regional follow up digest needs a value"),
                RegionalFollowUpDigestCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
