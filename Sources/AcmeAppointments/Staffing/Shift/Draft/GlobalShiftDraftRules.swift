import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a global shift draft must pass. Check returns its problems, or none.
    protocol GlobalShiftDraftRule {
        func check(_ item: GlobalShiftDraft) -> [String]
    }

    final class GlobalShiftDraftCodeLengthRule: GlobalShiftDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalShiftDraft) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalShiftDraftLabelLengthRule: GlobalShiftDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalShiftDraft) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalShiftDraftBedLengthRule: GlobalShiftDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalShiftDraft) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global shift draft.
    final class GlobalShiftDraftValidator {
        var rules: [any GlobalShiftDraftRule]

        init(rules: [any GlobalShiftDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalShiftDraft) -> [String] {
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

        func requireValid(_ item: GlobalShiftDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalShiftDraft]) -> [String: [String]] {
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

    static func defaultGlobalShiftDraftValidator() -> GlobalShiftDraftValidator {
        return GlobalShiftDraftValidator(
            rules: [
                GlobalShiftDraftCodeLengthRule(maxLength: 3600),
                GlobalShiftDraftLabelLengthRule(maxLength: 120),
                GlobalShiftDraftBedLengthRule(maxLength: 86400),
            ]
        )
    }
}
