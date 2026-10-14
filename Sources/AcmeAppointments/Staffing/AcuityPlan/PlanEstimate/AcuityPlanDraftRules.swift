import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a acuity plan draft must pass. Check returns its problems, or none.
    protocol AcuityPlanDraftRule {
        func check(_ item: AcuityPlanDraft) -> [String]
    }

    final class AcuityPlanDraftAcuityRangeRule: AcuityPlanDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AcuityPlanDraft) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AcuityPlanDraftAllergyLengthRule: AcuityPlanDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanDraft) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AcuityPlanDraftSummaryLengthRule: AcuityPlanDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanDraft) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AcuityPlanDraftCodePrefixRule: AcuityPlanDraftRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AcuityPlanDraft) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AcuityPlanDraftLabelLengthRule: AcuityPlanDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanDraft) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AcuityPlanDraftRequiredLabelRule: AcuityPlanDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AcuityPlanDraft) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a acuity plan draft.
    final class AcuityPlanDraftValidator {
        var rules: [any AcuityPlanDraftRule]

        init(rules: [any AcuityPlanDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: AcuityPlanDraft) -> [String] {
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

        func requireValid(_ item: AcuityPlanDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AcuityPlanDraft]) -> [String: [String]] {
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

    static func defaultAcuityPlanDraftValidator() -> AcuityPlanDraftValidator {
        return AcuityPlanDraftValidator(
            rules: [
                AcuityPlanDraftAcuityRangeRule(min: 16, max: 64),
                AcuityPlanDraftAllergyLengthRule(maxLength: 80),
                AcuityPlanDraftSummaryLengthRule(maxLength: 16),
                AcuityPlanDraftCodePrefixRule(prefix: "OPS"),
                AcuityPlanDraftLabelLengthRule(maxLength: 64),
                AcuityPlanDraftRequiredLabelRule(message: "acuity plan draft needs an entry"),
            ]
        )
    }
}
