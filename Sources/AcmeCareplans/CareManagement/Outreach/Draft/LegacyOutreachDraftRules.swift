import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a legacy outreach draft must pass. Check returns its problems, or none.
    protocol LegacyOutreachDraftRule {
        func check(_ item: LegacyOutreachDraft) -> [String]
    }

    final class LegacyOutreachDraftRequiredCodeRule: LegacyOutreachDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyOutreachDraft) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyOutreachDraftCodeLengthRule: LegacyOutreachDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyOutreachDraft) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyOutreachDraftDosageMgRangeRule: LegacyOutreachDraftRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyOutreachDraft) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LegacyOutreachDraftNameLengthRule: LegacyOutreachDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyOutreachDraft) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyOutreachDraftRequiredNameRule: LegacyOutreachDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyOutreachDraft) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a legacy outreach draft.
    final class LegacyOutreachDraftValidator {
        var rules: [any LegacyOutreachDraftRule]

        init(rules: [any LegacyOutreachDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyOutreachDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyOutreachDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyOutreachDraft]) -> [String: [String]] {
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

    static func defaultLegacyOutreachDraftValidator() -> LegacyOutreachDraftValidator {
        return LegacyOutreachDraftValidator(
            rules: [
                LegacyOutreachDraftRequiredCodeRule(message: "legacy outreach draft needs a value"),
                LegacyOutreachDraftCodeLengthRule(maxLength: 64),
                LegacyOutreachDraftDosageMgRangeRule(min: 4.1, max: 1620.8),
                LegacyOutreachDraftNameLengthRule(maxLength: 86400),
                LegacyOutreachDraftRequiredNameRule(message: "legacy outreach draft needs an entry"),
            ]
        )
    }
}
