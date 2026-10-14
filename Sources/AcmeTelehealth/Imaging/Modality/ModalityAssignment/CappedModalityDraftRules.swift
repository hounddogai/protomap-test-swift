import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a capped modality draft must pass. Check returns its problems, or none.
    protocol CappedModalityDraftRule {
        func check(_ item: CappedModalityDraft) -> [String]
    }

    final class CappedModalityDraftLabelLengthRule: CappedModalityDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedModalityDraft) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedModalityDraftAllergyLengthRule: CappedModalityDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedModalityDraft) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedModalityDraftMinimumRangeRule: CappedModalityDraftRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedModalityDraft) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CappedModalityDraftBudgetRangeRule: CappedModalityDraftRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedModalityDraft) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedModalityDraftCodePrefixRule: CappedModalityDraftRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedModalityDraft) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped modality draft.
    final class CappedModalityDraftValidator {
        var rules: [any CappedModalityDraftRule]

        init(rules: [any CappedModalityDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedModalityDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedModalityDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedModalityDraft]) -> [String: [String]] {
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

    static func defaultCappedModalityDraftValidator() -> CappedModalityDraftValidator {
        return CappedModalityDraftValidator(
            rules: [
                CappedModalityDraftLabelLengthRule(maxLength: 120),
                CappedModalityDraftAllergyLengthRule(maxLength: 120),
                CappedModalityDraftMinimumRangeRule(min: 1.1, max: 1506.6),
                CappedModalityDraftBudgetRangeRule(min: 9.4, max: 1258.3),
                CappedModalityDraftCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
