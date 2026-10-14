import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a regional slot batch must pass. Check returns its problems, or none.
    protocol RegionalSlotBatchRule {
        func check(_ item: RegionalSlotBatch) -> [String]
    }

    final class RegionalSlotBatchRequiredCategoryRule: RegionalSlotBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalSlotBatch) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalSlotBatchPinnedGuardRule: RegionalSlotBatchRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: RegionalSlotBatch) -> [String] {
            if item.pinned && (item.priority > limit) {
                return ["priority \(item.priority) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class RegionalSlotBatchCategoryLengthRule: RegionalSlotBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalSlotBatch) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional slot batch.
    final class RegionalSlotBatchValidator {
        var rules: [any RegionalSlotBatchRule]

        init(rules: [any RegionalSlotBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalSlotBatch) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalSlotBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalSlotBatch]) -> [String: [String]] {
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

    static func defaultRegionalSlotBatchValidator() -> RegionalSlotBatchValidator {
        return RegionalSlotBatchValidator(
            rules: [
                RegionalSlotBatchRequiredCategoryRule(message: "regional slot batch needs an entry"),
                RegionalSlotBatchPinnedGuardRule(limit: 80),
                RegionalSlotBatchCategoryLengthRule(maxLength: 1000),
            ]
        )
    }
}
