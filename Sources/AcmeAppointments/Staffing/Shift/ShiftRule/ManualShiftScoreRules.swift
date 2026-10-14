import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a manual shift score must pass. Check returns its problems, or none.
    protocol ManualShiftScoreRule {
        func check(_ item: ManualShiftScore) -> [String]
    }

    final class ManualShiftScoreChannelLengthRule: ManualShiftScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualShiftScore) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualShiftScoreNameLengthRule: ManualShiftScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualShiftScore) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualShiftScoreRequiredCodeRule: ManualShiftScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualShiftScore) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualShiftScoreCodeLengthRule: ManualShiftScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualShiftScore) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual shift score.
    final class ManualShiftScoreValidator {
        var rules: [any ManualShiftScoreRule]

        init(rules: [any ManualShiftScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualShiftScore) -> [String] {
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

        func requireValid(_ item: ManualShiftScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualShiftScore]) -> [String: [String]] {
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

    static func defaultManualShiftScoreValidator() -> ManualShiftScoreValidator {
        return ManualShiftScoreValidator(
            rules: [
                ManualShiftScoreChannelLengthRule(maxLength: 80),
                ManualShiftScoreNameLengthRule(maxLength: 16),
                ManualShiftScoreRequiredCodeRule(message: "manual shift score needs an entry"),
                ManualShiftScoreCodeLengthRule(maxLength: 80),
            ]
        )
    }
}
