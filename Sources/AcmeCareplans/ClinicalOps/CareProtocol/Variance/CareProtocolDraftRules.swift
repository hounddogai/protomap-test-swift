import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a care protocol draft must pass. Check returns its problems, or none.
    protocol CareProtocolDraftRule {
        func check(_ item: CareProtocolDraft) -> [String]
    }

    final class CareProtocolDraftRequiredReviewerRule: CareProtocolDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolDraft) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolDraftNameLengthRule: CareProtocolDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolDraft) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolDraftReviewerLengthRule: CareProtocolDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolDraft) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolDraftCodeLengthRule: CareProtocolDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolDraft) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolDraftAmountRangeRule: CareProtocolDraftRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolDraft) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CareProtocolDraftRequiredCodeRule: CareProtocolDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolDraft) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a care protocol draft.
    final class CareProtocolDraftValidator {
        var rules: [any CareProtocolDraftRule]

        init(rules: [any CareProtocolDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CareProtocolDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolDraft]) -> [String: [String]] {
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

    static func defaultCareProtocolDraftValidator() -> CareProtocolDraftValidator {
        return CareProtocolDraftValidator(
            rules: [
                CareProtocolDraftRequiredReviewerRule(message: "care protocol draft needs a value"),
                CareProtocolDraftNameLengthRule(maxLength: 80),
                CareProtocolDraftReviewerLengthRule(maxLength: 32),
                CareProtocolDraftCodeLengthRule(maxLength: 1000),
                CareProtocolDraftAmountRangeRule(min: 2.0, max: 4441.0),
                CareProtocolDraftRequiredCodeRule(message: "care protocol draft needs an entry"),
            ]
        )
    }
}
