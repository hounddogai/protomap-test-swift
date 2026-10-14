import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a seasonal inventory rollup must pass. Check returns its problems, or none.
    protocol SeasonalInventoryRollupRule {
        func check(_ item: SeasonalInventoryRollup) -> [String]
    }

    final class SeasonalInventoryRollupRequiredCodeRule: SeasonalInventoryRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalInventoryRollup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalInventoryRollupArchivedGuardRule: SeasonalInventoryRollupRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: SeasonalInventoryRollup) -> [String] {
            if item.archived && (item.createdAt > limit) {
                return ["created at \(item.createdAt) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class SeasonalInventoryRollupCategoryLengthRule: SeasonalInventoryRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalInventoryRollup) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalInventoryRollupRequiredCategoryRule: SeasonalInventoryRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalInventoryRollup) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalInventoryRollupRequiredClinicianIDRule: SeasonalInventoryRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalInventoryRollup) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalInventoryRollupTitleLengthRule: SeasonalInventoryRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalInventoryRollup) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal inventory rollup.
    final class SeasonalInventoryRollupValidator {
        var rules: [any SeasonalInventoryRollupRule]

        init(rules: [any SeasonalInventoryRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalInventoryRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalInventoryRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalInventoryRollup]) -> [String: [String]] {
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

    static func defaultSeasonalInventoryRollupValidator() -> SeasonalInventoryRollupValidator {
        return SeasonalInventoryRollupValidator(
            rules: [
                SeasonalInventoryRollupRequiredCodeRule(message: "seasonal inventory rollup needs a value"),
                SeasonalInventoryRollupArchivedGuardRule(limit: 80),
                SeasonalInventoryRollupCategoryLengthRule(maxLength: 1000),
                SeasonalInventoryRollupRequiredCategoryRule(message: "seasonal inventory rollup needs this field"),
                SeasonalInventoryRollupRequiredClinicianIDRule(message: "seasonal inventory rollup needs a value"),
                SeasonalInventoryRollupTitleLengthRule(maxLength: 120),
            ]
        )
    }
}
