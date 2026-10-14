import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a lenient study draft must pass. Check returns its problems, or none.
    protocol LenientStudyDraftRule {
        func check(_ item: LenientStudyDraft) -> [String]
    }

    final class LenientStudyDraftRevisionRangeRule: LenientStudyDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientStudyDraft) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientStudyDraftRegionLengthRule: LenientStudyDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientStudyDraft) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientStudyDraftCodeLengthRule: LenientStudyDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientStudyDraft) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientStudyDraftRequiredCodeRule: LenientStudyDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientStudyDraft) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientStudyDraftRequiredRegionRule: LenientStudyDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientStudyDraft) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientStudyDraftCodePrefixRule: LenientStudyDraftRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LenientStudyDraft) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient study draft.
    final class LenientStudyDraftValidator {
        var rules: [any LenientStudyDraftRule]

        init(rules: [any LenientStudyDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientStudyDraft) -> [String] {
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

        func requireValid(_ item: LenientStudyDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientStudyDraft]) -> [String: [String]] {
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

    static func defaultLenientStudyDraftValidator() -> LenientStudyDraftValidator {
        return LenientStudyDraftValidator(
            rules: [
                LenientStudyDraftRevisionRangeRule(min: 32, max: 120),
                LenientStudyDraftRegionLengthRule(maxLength: 32),
                LenientStudyDraftCodeLengthRule(maxLength: 1000),
                LenientStudyDraftRequiredCodeRule(message: "lenient study draft needs this field"),
                LenientStudyDraftRequiredRegionRule(message: "lenient study draft needs this field"),
                LenientStudyDraftCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
