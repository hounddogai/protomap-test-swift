import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a care gap digest must pass. Check returns its problems, or none.
    protocol CareGapDigestRule {
        func check(_ item: CareGapDigest) -> [String]
    }

    final class CareGapDigestQuantityRangeRule: CareGapDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareGapDigest) -> [String] {
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

    final class CareGapDigestAllowedDescriptionRule: CareGapDigestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CareGapDigest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.description)) {
                return ["description \(item.description) is stale"]
            }
            return []
        }
    }

    final class CareGapDigestTagsLimitRule: CareGapDigestRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: CareGapDigest) -> [String] {
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

    /// Runs every rule of a care gap digest.
    final class CareGapDigestValidator {
        var rules: [any CareGapDigestRule]

        init(rules: [any CareGapDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: CareGapDigest) -> [String] {
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

        func requireValid(_ item: CareGapDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareGapDigest]) -> [String: [String]] {
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

    static func defaultCareGapDigestValidator() -> CareGapDigestValidator {
        return CareGapDigestValidator(
            rules: [
                CareGapDigestQuantityRangeRule(min: 32, max: 64),
                CareGapDigestAllowedDescriptionRule(allowed: []),
                CareGapDigestTagsLimitRule(maxCount: 32, banned: ["global"]),
            ]
        )
    }
}
