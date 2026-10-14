import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a strict claim digest must pass. Check returns its problems, or none.
    protocol StrictClaimDigestRule {
        func check(_ item: StrictClaimDigest) -> [String]
    }

    final class StrictClaimDigestTagsLimitRule: StrictClaimDigestRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: StrictClaimDigest) -> [String] {
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

    final class StrictClaimDigestCreatedAtRangeRule: StrictClaimDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictClaimDigest) -> [String] {
            let value = item.createdAt
            var problems: [String] = []
            if value < min {
                problems.append("created at \(value) is below \(min)")
            }
            if value > max {
                problems.append("created at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StrictClaimDigestCodePrefixRule: StrictClaimDigestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StrictClaimDigest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StrictClaimDigestAllergyLengthRule: StrictClaimDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictClaimDigest) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictClaimDigestCodeLengthRule: StrictClaimDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictClaimDigest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict claim digest.
    final class StrictClaimDigestValidator {
        var rules: [any StrictClaimDigestRule]

        init(rules: [any StrictClaimDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictClaimDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictClaimDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictClaimDigest]) -> [String: [String]] {
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

    static func defaultStrictClaimDigestValidator() -> StrictClaimDigestValidator {
        return StrictClaimDigestValidator(
            rules: [
                StrictClaimDigestTagsLimitRule(maxCount: 255, banned: []),
                StrictClaimDigestCreatedAtRangeRule(min: 16, max: 80),
                StrictClaimDigestCodePrefixRule(prefix: "ACM"),
                StrictClaimDigestAllergyLengthRule(maxLength: 1000),
                StrictClaimDigestCodeLengthRule(maxLength: 80),
            ]
        )
    }
}
