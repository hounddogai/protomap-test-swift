import AcmePlatform
import Foundation

extension Consent {
    /// A rule a revocation batch must pass. Check returns its problems, or none.
    protocol RevocationBatchRule {
        func check(_ item: RevocationBatch) -> [String]
    }

    final class RevocationBatchAllowedLabelRule: RevocationBatchRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RevocationBatch) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is blocked"]
            }
            return []
        }
    }

    final class RevocationBatchRequiredLabelRule: RevocationBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RevocationBatch) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RevocationBatchCodeLengthRule: RevocationBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RevocationBatch) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RevocationBatchRequiredCodeRule: RevocationBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RevocationBatch) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RevocationBatchTagsLimitRule: RevocationBatchRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: RevocationBatch) -> [String] {
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

    /// Runs every rule of a revocation batch.
    final class RevocationBatchValidator {
        var rules: [any RevocationBatchRule]

        init(rules: [any RevocationBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: RevocationBatch) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RevocationBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RevocationBatch]) -> [String: [String]] {
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

    static func defaultRevocationBatchValidator() -> RevocationBatchValidator {
        return RevocationBatchValidator(
            rules: [
                RevocationBatchAllowedLabelRule(allowed: ["global", "manual", "scheduled"]),
                RevocationBatchRequiredLabelRule(message: "revocation batch needs this field"),
                RevocationBatchCodeLengthRule(maxLength: 255),
                RevocationBatchRequiredCodeRule(message: "revocation batch needs a value"),
                RevocationBatchTagsLimitRule(maxCount: 86400, banned: []),
            ]
        )
    }
}
