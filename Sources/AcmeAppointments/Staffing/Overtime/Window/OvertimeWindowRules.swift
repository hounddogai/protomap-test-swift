import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a overtime window must pass. Check returns its problems, or none.
    protocol OvertimeWindowRule {
        func check(_ item: OvertimeWindow) -> [String]
    }

    final class OvertimeWindowRequiredTitleRule: OvertimeWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeWindow) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OvertimeWindowTitleLengthRule: OvertimeWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OvertimeWindow) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OvertimeWindowRequiredDescriptionRule: OvertimeWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeWindow) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OvertimeWindowRequiredCodeRule: OvertimeWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeWindow) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a overtime window.
    final class OvertimeWindowValidator {
        var rules: [any OvertimeWindowRule]

        init(rules: [any OvertimeWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: OvertimeWindow) -> [String] {
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

        func requireValid(_ item: OvertimeWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OvertimeWindow]) -> [String: [String]] {
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

    static func defaultOvertimeWindowValidator() -> OvertimeWindowValidator {
        return OvertimeWindowValidator(
            rules: [
                OvertimeWindowRequiredTitleRule(message: "overtime window needs a value"),
                OvertimeWindowTitleLengthRule(maxLength: 16),
                OvertimeWindowRequiredDescriptionRule(message: "overtime window needs this field"),
                OvertimeWindowRequiredCodeRule(message: "overtime window needs this field"),
            ]
        )
    }
}
