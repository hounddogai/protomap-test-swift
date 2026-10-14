import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a tiered task milestone must pass. Check returns its problems, or none.
    protocol TieredTaskMilestoneRule {
        func check(_ item: TieredTaskMilestone) -> [String]
    }

    final class TieredTaskMilestoneCodePrefixRule: TieredTaskMilestoneRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredTaskMilestone) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredTaskMilestoneCategoryLengthRule: TieredTaskMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredTaskMilestone) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredTaskMilestoneRequiredSpecialtyRule: TieredTaskMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredTaskMilestone) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredTaskMilestoneRequiredCodeRule: TieredTaskMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredTaskMilestone) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredTaskMilestoneCodeLengthRule: TieredTaskMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredTaskMilestone) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered task milestone.
    final class TieredTaskMilestoneValidator {
        var rules: [any TieredTaskMilestoneRule]

        init(rules: [any TieredTaskMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredTaskMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredTaskMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredTaskMilestone]) -> [String: [String]] {
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

    static func defaultTieredTaskMilestoneValidator() -> TieredTaskMilestoneValidator {
        return TieredTaskMilestoneValidator(
            rules: [
                TieredTaskMilestoneCodePrefixRule(prefix: "OPS"),
                TieredTaskMilestoneCategoryLengthRule(maxLength: 64),
                TieredTaskMilestoneRequiredSpecialtyRule(message: "tiered task milestone needs an entry"),
                TieredTaskMilestoneRequiredCodeRule(message: "tiered task milestone needs a value"),
                TieredTaskMilestoneCodeLengthRule(maxLength: 120),
            ]
        )
    }
}
