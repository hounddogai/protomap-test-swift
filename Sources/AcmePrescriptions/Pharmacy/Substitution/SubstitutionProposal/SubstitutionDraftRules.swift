import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a substitution draft must pass. Check returns its problems, or none.
    protocol SubstitutionDraftRule {
        func check(_ item: SubstitutionDraft) -> [String]
    }

    final class SubstitutionDraftNameLengthRule: SubstitutionDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SubstitutionDraft) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SubstitutionDraftRatioRangeRule: SubstitutionDraftRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SubstitutionDraft) -> [String] {
            let value = item.ratio
            var problems: [String] = []
            if value < min {
                problems.append("ratio \(value) is below \(min)")
            }
            if value > max {
                problems.append("ratio \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SubstitutionDraftRequiredNameRule: SubstitutionDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SubstitutionDraft) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SubstitutionDraftCodePrefixRule: SubstitutionDraftRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SubstitutionDraft) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SubstitutionDraftSummaryLengthRule: SubstitutionDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SubstitutionDraft) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a substitution draft.
    final class SubstitutionDraftValidator {
        var rules: [any SubstitutionDraftRule]

        init(rules: [any SubstitutionDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: SubstitutionDraft) -> [String] {
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

        func requireValid(_ item: SubstitutionDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SubstitutionDraft]) -> [String: [String]] {
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

    static func defaultSubstitutionDraftValidator() -> SubstitutionDraftValidator {
        return SubstitutionDraftValidator(
            rules: [
                SubstitutionDraftNameLengthRule(maxLength: 1000),
                SubstitutionDraftRatioRangeRule(min: 5.3, max: 3261.2),
                SubstitutionDraftRequiredNameRule(message: "substitution draft needs this field"),
                SubstitutionDraftCodePrefixRule(prefix: "ACM"),
                SubstitutionDraftSummaryLengthRule(maxLength: 64),
            ]
        )
    }
}
