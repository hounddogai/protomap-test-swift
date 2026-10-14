import AcmePlatform
import Foundation

extension Labs {
    /// A rule a legacy reference range profile must pass. Check returns its problems, or none.
    protocol LegacyReferenceRangeProfileRule {
        func check(_ item: LegacyReferenceRangeProfile) -> [String]
    }

    final class LegacyReferenceRangeProfileRequiredSummaryRule: LegacyReferenceRangeProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyReferenceRangeProfile) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyReferenceRangeProfileRequiredLabelRule: LegacyReferenceRangeProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyReferenceRangeProfile) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyReferenceRangeProfileRequiredCodeRule: LegacyReferenceRangeProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyReferenceRangeProfile) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a legacy reference range profile.
    final class LegacyReferenceRangeProfileValidator {
        var rules: [any LegacyReferenceRangeProfileRule]

        init(rules: [any LegacyReferenceRangeProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyReferenceRangeProfile) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyReferenceRangeProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyReferenceRangeProfile]) -> [String: [String]] {
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

    static func defaultLegacyReferenceRangeProfileValidator() -> LegacyReferenceRangeProfileValidator {
        return LegacyReferenceRangeProfileValidator(
            rules: [
                LegacyReferenceRangeProfileRequiredSummaryRule(
                    message: "legacy reference range profile needs a value"
                ),
                LegacyReferenceRangeProfileRequiredLabelRule(message: "legacy reference range profile needs an entry"),
                LegacyReferenceRangeProfileRequiredCodeRule(message: "legacy reference range profile needs an entry"),
            ]
        )
    }
}
