import AcmePlatform
import Foundation

extension Labs {
    /// A rule a reference range milestone must pass. Check returns its problems, or none.
    protocol ReferenceRangeMilestoneRule {
        func check(_ item: ReferenceRangeMilestone) -> [String]
    }

    final class ReferenceRangeMilestoneCodePrefixRule: ReferenceRangeMilestoneRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ReferenceRangeMilestone) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ReferenceRangeMilestoneCategoryLengthRule: ReferenceRangeMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferenceRangeMilestone) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferenceRangeMilestoneLabelLengthRule: ReferenceRangeMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferenceRangeMilestone) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferenceRangeMilestoneAllowedCodeRule: ReferenceRangeMilestoneRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ReferenceRangeMilestone) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is duplicated"]
            }
            return []
        }
    }

    final class ReferenceRangeMilestoneRequiredLabelRule: ReferenceRangeMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferenceRangeMilestone) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferenceRangeMilestoneRequiredCategoryRule: ReferenceRangeMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferenceRangeMilestone) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a reference range milestone.
    final class ReferenceRangeMilestoneValidator {
        var rules: [any ReferenceRangeMilestoneRule]

        init(rules: [any ReferenceRangeMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferenceRangeMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReferenceRangeMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferenceRangeMilestone]) -> [String: [String]] {
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

    static func defaultReferenceRangeMilestoneValidator() -> ReferenceRangeMilestoneValidator {
        return ReferenceRangeMilestoneValidator(
            rules: [
                ReferenceRangeMilestoneCodePrefixRule(prefix: "REF"),
                ReferenceRangeMilestoneCategoryLengthRule(maxLength: 120),
                ReferenceRangeMilestoneLabelLengthRule(maxLength: 1000),
                ReferenceRangeMilestoneAllowedCodeRule(allowed: []),
                ReferenceRangeMilestoneRequiredLabelRule(message: "reference range milestone needs a value"),
                ReferenceRangeMilestoneRequiredCategoryRule(message: "reference range milestone needs an entry"),
            ]
        )
    }
}
