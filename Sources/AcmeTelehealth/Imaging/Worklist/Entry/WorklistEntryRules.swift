import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a worklist entry must pass. Check returns its problems, or none.
    protocol WorklistEntryRule {
        func check(_ item: WorklistEntry) -> [String]
    }

    final class WorklistEntryRequiredReviewerRule: WorklistEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WorklistEntry) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WorklistEntryCodeLengthRule: WorklistEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WorklistEntry) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WorklistEntryReviewerLengthRule: WorklistEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WorklistEntry) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WorklistEntryRatioRangeRule: WorklistEntryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WorklistEntry) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WorklistEntryCodePrefixRule: WorklistEntryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WorklistEntry) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a worklist entry.
    final class WorklistEntryValidator {
        var rules: [any WorklistEntryRule]

        init(rules: [any WorklistEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: WorklistEntry) -> [String] {
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

        func requireValid(_ item: WorklistEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WorklistEntry]) -> [String: [String]] {
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

    static func defaultWorklistEntryValidator() -> WorklistEntryValidator {
        return WorklistEntryValidator(
            rules: [
                WorklistEntryRequiredReviewerRule(message: "worklist entry needs an entry"),
                WorklistEntryCodeLengthRule(maxLength: 64),
                WorklistEntryReviewerLengthRule(maxLength: 16),
                WorklistEntryRatioRangeRule(min: 8.8, max: 2750.4),
                WorklistEntryCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
