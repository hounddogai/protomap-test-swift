import AcmePlatform
import Foundation

extension Consent {
    /// A rule a revocation adjustment must pass. Check returns its problems, or none.
    protocol RevocationAdjustmentRule {
        func check(_ item: RevocationAdjustment) -> [String]
    }

    final class RevocationAdjustmentRequiredTitleRule: RevocationAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RevocationAdjustment) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RevocationAdjustmentBatchSizeRangeRule: RevocationAdjustmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RevocationAdjustment) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RevocationAdjustmentTagsLimitRule: RevocationAdjustmentRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: RevocationAdjustment) -> [String] {
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

    final class RevocationAdjustmentTitleLengthRule: RevocationAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RevocationAdjustment) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RevocationAdjustmentAllowedPhoneRule: RevocationAdjustmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RevocationAdjustment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.phone)) {
                return ["phone \(item.phone) is stale"]
            }
            return []
        }
    }

    /// Runs every rule of a revocation adjustment.
    final class RevocationAdjustmentValidator {
        var rules: [any RevocationAdjustmentRule]

        init(rules: [any RevocationAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: RevocationAdjustment) -> [String] {
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

        func requireValid(_ item: RevocationAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RevocationAdjustment]) -> [String: [String]] {
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

    static func defaultRevocationAdjustmentValidator() -> RevocationAdjustmentValidator {
        return RevocationAdjustmentValidator(
            rules: [
                RevocationAdjustmentRequiredTitleRule(message: "revocation adjustment needs a value"),
                RevocationAdjustmentBatchSizeRangeRule(min: 120, max: 255),
                RevocationAdjustmentTagsLimitRule(maxCount: 16, banned: ["lenient"]),
                RevocationAdjustmentTitleLengthRule(maxLength: 64),
                RevocationAdjustmentAllowedPhoneRule(allowed: []),
            ]
        )
    }
}
