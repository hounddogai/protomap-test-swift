import AcmePlatform
import Foundation

extension Labs {
    /// A rule a fallback courier draft must pass. Check returns its problems, or none.
    protocol FallbackCourierDraftRule {
        func check(_ item: FallbackCourierDraft) -> [String]
    }

    final class FallbackCourierDraftRequiredLabelRule: FallbackCourierDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackCourierDraft) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackCourierDraftLabelLengthRule: FallbackCourierDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackCourierDraft) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackCourierDraftReviewerLengthRule: FallbackCourierDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackCourierDraft) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback courier draft.
    final class FallbackCourierDraftValidator {
        var rules: [any FallbackCourierDraftRule]

        init(rules: [any FallbackCourierDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackCourierDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackCourierDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackCourierDraft]) -> [String: [String]] {
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

    static func defaultFallbackCourierDraftValidator() -> FallbackCourierDraftValidator {
        return FallbackCourierDraftValidator(
            rules: [
                FallbackCourierDraftRequiredLabelRule(message: "fallback courier draft needs a value"),
                FallbackCourierDraftLabelLengthRule(maxLength: 120),
                FallbackCourierDraftReviewerLengthRule(maxLength: 80),
            ]
        )
    }
}
