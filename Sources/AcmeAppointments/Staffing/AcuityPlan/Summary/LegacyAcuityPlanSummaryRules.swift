import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a legacy acuity plan summary must pass. Check returns its problems, or none.
    protocol LegacyAcuityPlanSummaryRule {
        func check(_ item: LegacyAcuityPlanSummary) -> [String]
    }

    final class LegacyAcuityPlanSummaryContactEmailLengthRule: LegacyAcuityPlanSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyAcuityPlanSummary) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyAcuityPlanSummaryRequiredTitleRule: LegacyAcuityPlanSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyAcuityPlanSummary) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyAcuityPlanSummaryRequiredContactEmailRule: LegacyAcuityPlanSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyAcuityPlanSummary) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyAcuityPlanSummaryRequiredSegmentRule: LegacyAcuityPlanSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyAcuityPlanSummary) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyAcuityPlanSummaryRequiredCodeRule: LegacyAcuityPlanSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyAcuityPlanSummary) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a legacy acuity plan summary.
    final class LegacyAcuityPlanSummaryValidator {
        var rules: [any LegacyAcuityPlanSummaryRule]

        init(rules: [any LegacyAcuityPlanSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyAcuityPlanSummary) -> [String] {
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

        func requireValid(_ item: LegacyAcuityPlanSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyAcuityPlanSummary]) -> [String: [String]] {
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

    static func defaultLegacyAcuityPlanSummaryValidator() -> LegacyAcuityPlanSummaryValidator {
        return LegacyAcuityPlanSummaryValidator(
            rules: [
                LegacyAcuityPlanSummaryContactEmailLengthRule(maxLength: 64),
                LegacyAcuityPlanSummaryRequiredTitleRule(message: "legacy acuity plan summary needs an entry"),
                LegacyAcuityPlanSummaryRequiredContactEmailRule(message: "legacy acuity plan summary needs an entry"),
                LegacyAcuityPlanSummaryRequiredSegmentRule(message: "legacy acuity plan summary needs this field"),
                LegacyAcuityPlanSummaryRequiredCodeRule(message: "legacy acuity plan summary needs this field"),
            ]
        )
    }
}
