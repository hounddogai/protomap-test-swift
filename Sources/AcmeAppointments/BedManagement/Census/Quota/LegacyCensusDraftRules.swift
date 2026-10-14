import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a legacy census draft must pass. Check returns its problems, or none.
    protocol LegacyCensusDraftRule {
        func check(_ item: LegacyCensusDraft) -> [String]
    }

    final class LegacyCensusDraftCodeLengthRule: LegacyCensusDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyCensusDraft) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyCensusDraftRequiredReviewerRule: LegacyCensusDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyCensusDraft) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyCensusDraftRequiredCodeRule: LegacyCensusDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyCensusDraft) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyCensusDraftUpdatedAtRangeRule: LegacyCensusDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyCensusDraft) -> [String] {
            let value = item.updatedAt
            var problems: [String] = []
            if value < min {
                problems.append("updated at \(value) is below \(min)")
            }
            if value > max {
                problems.append("updated at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a legacy census draft.
    final class LegacyCensusDraftValidator {
        var rules: [any LegacyCensusDraftRule]

        init(rules: [any LegacyCensusDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyCensusDraft) -> [String] {
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

        func requireValid(_ item: LegacyCensusDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyCensusDraft]) -> [String: [String]] {
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

    static func defaultLegacyCensusDraftValidator() -> LegacyCensusDraftValidator {
        return LegacyCensusDraftValidator(
            rules: [
                LegacyCensusDraftCodeLengthRule(maxLength: 120),
                LegacyCensusDraftRequiredReviewerRule(message: "legacy census draft needs a value"),
                LegacyCensusDraftRequiredCodeRule(message: "legacy census draft needs this field"),
                LegacyCensusDraftUpdatedAtRangeRule(min: 80, max: 86400),
            ]
        )
    }
}
