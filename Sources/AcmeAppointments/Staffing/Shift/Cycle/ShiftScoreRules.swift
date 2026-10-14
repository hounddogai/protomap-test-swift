import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a shift score must pass. Check returns its problems, or none.
    protocol ShiftScoreRule {
        func check(_ item: ShiftScore) -> [String]
    }

    final class ShiftScoreRequiredNameRule: ShiftScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ShiftScore) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ShiftScoreRequiredCodeRule: ShiftScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ShiftScore) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ShiftScoreCodePrefixRule: ShiftScoreRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ShiftScore) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ShiftScoreNameLengthRule: ShiftScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ShiftScore) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ShiftScoreRequiredTitleRule: ShiftScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ShiftScore) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ShiftScoreTitleLengthRule: ShiftScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ShiftScore) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a shift score.
    final class ShiftScoreValidator {
        var rules: [any ShiftScoreRule]

        init(rules: [any ShiftScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: ShiftScore) -> [String] {
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

        func requireValid(_ item: ShiftScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ShiftScore]) -> [String: [String]] {
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

    static func defaultShiftScoreValidator() -> ShiftScoreValidator {
        return ShiftScoreValidator(
            rules: [
                ShiftScoreRequiredNameRule(message: "shift score needs a value"),
                ShiftScoreRequiredCodeRule(message: "shift score needs a value"),
                ShiftScoreCodePrefixRule(prefix: "OPS"),
                ShiftScoreNameLengthRule(maxLength: 120),
                ShiftScoreRequiredTitleRule(message: "shift score needs a value"),
                ShiftScoreTitleLengthRule(maxLength: 1000),
            ]
        )
    }
}
