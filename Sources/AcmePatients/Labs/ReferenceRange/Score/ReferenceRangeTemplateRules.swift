import AcmePlatform
import Foundation

extension Labs {
    /// A rule a reference range template must pass. Check returns its problems, or none.
    protocol ReferenceRangeTemplateRule {
        func check(_ item: ReferenceRangeTemplate) -> [String]
    }

    final class ReferenceRangeTemplateRequiredLabelRule: ReferenceRangeTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferenceRangeTemplate) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferenceRangeTemplateLabelLengthRule: ReferenceRangeTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferenceRangeTemplate) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferenceRangeTemplateCreatedAtRangeRule: ReferenceRangeTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferenceRangeTemplate) -> [String] {
            let value = item.createdAt
            var problems: [String] = []
            if value < min {
                problems.append("created at \(value) is below \(min)")
            }
            if value > max {
                problems.append("created at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ReferenceRangeTemplateAllowedLabelRule: ReferenceRangeTemplateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ReferenceRangeTemplate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is unknown"]
            }
            return []
        }
    }

    final class ReferenceRangeTemplateRequiredTitleRule: ReferenceRangeTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferenceRangeTemplate) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferenceRangeTemplateEncounterIDLengthRule: ReferenceRangeTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferenceRangeTemplate) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a reference range template.
    final class ReferenceRangeTemplateValidator {
        var rules: [any ReferenceRangeTemplateRule]

        init(rules: [any ReferenceRangeTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferenceRangeTemplate) -> [String] {
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

        func requireValid(_ item: ReferenceRangeTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferenceRangeTemplate]) -> [String: [String]] {
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

    static func defaultReferenceRangeTemplateValidator() -> ReferenceRangeTemplateValidator {
        return ReferenceRangeTemplateValidator(
            rules: [
                ReferenceRangeTemplateRequiredLabelRule(message: "reference range template needs this field"),
                ReferenceRangeTemplateLabelLengthRule(maxLength: 86400),
                ReferenceRangeTemplateCreatedAtRangeRule(min: 16, max: 3600),
                ReferenceRangeTemplateAllowedLabelRule(allowed: []),
                ReferenceRangeTemplateRequiredTitleRule(message: "reference range template needs a value"),
                ReferenceRangeTemplateEncounterIDLengthRule(maxLength: 120),
            ]
        )
    }
}
