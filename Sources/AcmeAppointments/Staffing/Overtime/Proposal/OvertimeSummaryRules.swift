import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a overtime summary must pass. Check returns its problems, or none.
    protocol OvertimeSummaryRule {
        func check(_ item: OvertimeSummary) -> [String]
    }

    final class OvertimeSummaryPinnedGuardRule: OvertimeSummaryRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: OvertimeSummary) -> [String] {
            if item.pinned && (item.ratio > limit) {
                return ["ratio \(item.ratio) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class OvertimeSummaryCodeLengthRule: OvertimeSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OvertimeSummary) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OvertimeSummaryRequiredTitleRule: OvertimeSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeSummary) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a overtime summary.
    final class OvertimeSummaryValidator {
        var rules: [any OvertimeSummaryRule]

        init(rules: [any OvertimeSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: OvertimeSummary) -> [String] {
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

        func requireValid(_ item: OvertimeSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OvertimeSummary]) -> [String: [String]] {
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

    static func defaultOvertimeSummaryValidator() -> OvertimeSummaryValidator {
        return OvertimeSummaryValidator(
            rules: [
                OvertimeSummaryPinnedGuardRule(limit: 0.6),
                OvertimeSummaryCodeLengthRule(maxLength: 16),
                OvertimeSummaryRequiredTitleRule(message: "overtime summary needs this field"),
            ]
        )
    }
}
