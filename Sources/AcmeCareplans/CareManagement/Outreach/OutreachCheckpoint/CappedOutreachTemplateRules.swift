import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a capped outreach template must pass. Check returns its problems, or none.
    protocol CappedOutreachTemplateRule {
        func check(_ item: CappedOutreachTemplate) -> [String]
    }

    final class CappedOutreachTemplateCodeLengthRule: CappedOutreachTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedOutreachTemplate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedOutreachTemplateRequiredPatientRefRule: CappedOutreachTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedOutreachTemplate) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedOutreachTemplateLabelLengthRule: CappedOutreachTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedOutreachTemplate) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedOutreachTemplatePinnedGuardRule: CappedOutreachTemplateRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: CappedOutreachTemplate) -> [String] {
            if item.pinned && (item.amount > limit) {
                return ["amount \(item.amount) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    /// Runs every rule of a capped outreach template.
    final class CappedOutreachTemplateValidator {
        var rules: [any CappedOutreachTemplateRule]

        init(rules: [any CappedOutreachTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedOutreachTemplate) -> [String] {
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

        func requireValid(_ item: CappedOutreachTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedOutreachTemplate]) -> [String: [String]] {
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

    static func defaultCappedOutreachTemplateValidator() -> CappedOutreachTemplateValidator {
        return CappedOutreachTemplateValidator(
            rules: [
                CappedOutreachTemplateCodeLengthRule(maxLength: 1000),
                CappedOutreachTemplateRequiredPatientRefRule(message: "capped outreach template needs a value"),
                CappedOutreachTemplateLabelLengthRule(maxLength: 120),
                CappedOutreachTemplatePinnedGuardRule(limit: 8.1),
            ]
        )
    }
}
