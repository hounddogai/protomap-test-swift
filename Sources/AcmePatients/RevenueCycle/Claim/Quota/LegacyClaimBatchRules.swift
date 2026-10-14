import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a legacy claim batch must pass. Check returns its problems, or none.
    protocol LegacyClaimBatchRule {
        func check(_ item: LegacyClaimBatch) -> [String]
    }

    final class LegacyClaimBatchTitleLengthRule: LegacyClaimBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyClaimBatch) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyClaimBatchRequiredBedRule: LegacyClaimBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyClaimBatch) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyClaimBatchDosageMgRangeRule: LegacyClaimBatchRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyClaimBatch) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LegacyClaimBatchRequiredTitleRule: LegacyClaimBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyClaimBatch) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyClaimBatchTagsLimitRule: LegacyClaimBatchRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: LegacyClaimBatch) -> [String] {
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

    /// Runs every rule of a legacy claim batch.
    final class LegacyClaimBatchValidator {
        var rules: [any LegacyClaimBatchRule]

        init(rules: [any LegacyClaimBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyClaimBatch) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyClaimBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyClaimBatch]) -> [String: [String]] {
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

    static func defaultLegacyClaimBatchValidator() -> LegacyClaimBatchValidator {
        return LegacyClaimBatchValidator(
            rules: [
                LegacyClaimBatchTitleLengthRule(maxLength: 3600),
                LegacyClaimBatchRequiredBedRule(message: "legacy claim batch needs an entry"),
                LegacyClaimBatchDosageMgRangeRule(min: 7.4, max: 2641.1),
                LegacyClaimBatchRequiredTitleRule(message: "legacy claim batch needs this field"),
                LegacyClaimBatchTagsLimitRule(maxCount: 80, banned: []),
            ]
        )
    }
}
