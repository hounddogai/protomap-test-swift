import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a denial draft must pass. Check returns its problems, or none.
    protocol DenialDraftRule {
        func check(_ item: DenialDraft) -> [String]
    }

    final class DenialDraftCodePrefixRule: DenialDraftRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DenialDraft) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DenialDraftAllowedSegmentRule: DenialDraftRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DenialDraft) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.segment)) {
                return ["segment \(item.segment) is not allowed"]
            }
            return []
        }
    }

    final class DenialDraftRequiredLabelRule: DenialDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DenialDraft) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DenialDraftGraceDaysRangeRule: DenialDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DenialDraft) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DenialDraftCodeLengthRule: DenialDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DenialDraft) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a denial draft.
    final class DenialDraftValidator {
        var rules: [any DenialDraftRule]

        init(rules: [any DenialDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: DenialDraft) -> [String] {
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

        func requireValid(_ item: DenialDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DenialDraft]) -> [String: [String]] {
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

    static func defaultDenialDraftValidator() -> DenialDraftValidator {
        return DenialDraftValidator(
            rules: [
                DenialDraftCodePrefixRule(prefix: "X"),
                DenialDraftAllowedSegmentRule(allowed: ["adaptive"]),
                DenialDraftRequiredLabelRule(message: "denial draft needs an entry"),
                DenialDraftGraceDaysRangeRule(min: 1000, max: 1000),
                DenialDraftCodeLengthRule(maxLength: 1000),
            ]
        )
    }
}
