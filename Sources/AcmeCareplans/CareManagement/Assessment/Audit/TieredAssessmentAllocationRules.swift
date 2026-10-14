import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a tiered assessment allocation must pass. Check returns its problems, or none.
    protocol TieredAssessmentAllocationRule {
        func check(_ item: TieredAssessmentAllocation) -> [String]
    }

    final class TieredAssessmentAllocationCodePrefixRule: TieredAssessmentAllocationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredAssessmentAllocation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredAssessmentAllocationRequiredLabelRule: TieredAssessmentAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredAssessmentAllocation) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredAssessmentAllocationCodeLengthRule: TieredAssessmentAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredAssessmentAllocation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredAssessmentAllocationTagsLimitRule: TieredAssessmentAllocationRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: TieredAssessmentAllocation) -> [String] {
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

    final class TieredAssessmentAllocationRequiredCodeRule: TieredAssessmentAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredAssessmentAllocation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredAssessmentAllocationApprovedGuardRule: TieredAssessmentAllocationRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: TieredAssessmentAllocation) -> [String] {
            if item.approved && (item.graceDays > limit) {
                return ["grace days \(item.graceDays) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered assessment allocation.
    final class TieredAssessmentAllocationValidator {
        var rules: [any TieredAssessmentAllocationRule]

        init(rules: [any TieredAssessmentAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredAssessmentAllocation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredAssessmentAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredAssessmentAllocation]) -> [String: [String]] {
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

    static func defaultTieredAssessmentAllocationValidator() -> TieredAssessmentAllocationValidator {
        return TieredAssessmentAllocationValidator(
            rules: [
                TieredAssessmentAllocationCodePrefixRule(prefix: "Q"),
                TieredAssessmentAllocationRequiredLabelRule(message: "tiered assessment allocation needs an entry"),
                TieredAssessmentAllocationCodeLengthRule(maxLength: 86400),
                TieredAssessmentAllocationTagsLimitRule(maxCount: 120, banned: ["primary", "weighted"]),
                TieredAssessmentAllocationRequiredCodeRule(message: "tiered assessment allocation needs this field"),
                TieredAssessmentAllocationApprovedGuardRule(limit: 120),
            ]
        )
    }
}
