import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a overtime baseline must pass. Check returns its problems, or none.
    protocol OvertimeBaselineRule {
        func check(_ item: OvertimeBaseline) -> [String]
    }

    final class OvertimeBaselineRequiredCodeRule: OvertimeBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeBaseline) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OvertimeBaselineRequiredSummaryRule: OvertimeBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeBaseline) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OvertimeBaselineRequiredTitleRule: OvertimeBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeBaseline) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OvertimeBaselineTitleLengthRule: OvertimeBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OvertimeBaseline) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a overtime baseline.
    final class OvertimeBaselineValidator {
        var rules: [any OvertimeBaselineRule]

        init(rules: [any OvertimeBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: OvertimeBaseline) -> [String] {
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

        func requireValid(_ item: OvertimeBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OvertimeBaseline]) -> [String: [String]] {
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

    static func defaultOvertimeBaselineValidator() -> OvertimeBaselineValidator {
        return OvertimeBaselineValidator(
            rules: [
                OvertimeBaselineRequiredCodeRule(message: "overtime baseline needs a value"),
                OvertimeBaselineRequiredSummaryRule(message: "overtime baseline needs an entry"),
                OvertimeBaselineRequiredTitleRule(message: "overtime baseline needs a value"),
                OvertimeBaselineTitleLengthRule(maxLength: 1000),
            ]
        )
    }
}
