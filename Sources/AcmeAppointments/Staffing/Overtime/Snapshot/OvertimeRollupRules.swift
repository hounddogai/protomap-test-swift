import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a overtime rollup must pass. Check returns its problems, or none.
    protocol OvertimeRollupRule {
        func check(_ item: OvertimeRollup) -> [String]
    }

    final class OvertimeRollupWardLengthRule: OvertimeRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OvertimeRollup) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OvertimeRollupCodeLengthRule: OvertimeRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OvertimeRollup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OvertimeRollupLabelLengthRule: OvertimeRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OvertimeRollup) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OvertimeRollupRequiredLabelRule: OvertimeRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeRollup) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OvertimeRollupTitleLengthRule: OvertimeRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OvertimeRollup) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a overtime rollup.
    final class OvertimeRollupValidator {
        var rules: [any OvertimeRollupRule]

        init(rules: [any OvertimeRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: OvertimeRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: OvertimeRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OvertimeRollup]) -> [String: [String]] {
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

    static func defaultOvertimeRollupValidator() -> OvertimeRollupValidator {
        return OvertimeRollupValidator(
            rules: [
                OvertimeRollupWardLengthRule(maxLength: 32),
                OvertimeRollupCodeLengthRule(maxLength: 86400),
                OvertimeRollupLabelLengthRule(maxLength: 86400),
                OvertimeRollupRequiredLabelRule(message: "overtime rollup needs an entry"),
                OvertimeRollupTitleLengthRule(maxLength: 86400),
            ]
        )
    }
}
