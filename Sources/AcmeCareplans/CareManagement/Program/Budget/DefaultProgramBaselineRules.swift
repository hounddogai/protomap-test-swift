import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a default program baseline must pass. Check returns its problems, or none.
    protocol DefaultProgramBaselineRule {
        func check(_ item: DefaultProgramBaseline) -> [String]
    }

    final class DefaultProgramBaselineCodePrefixRule: DefaultProgramBaselineRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultProgramBaseline) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DefaultProgramBaselineRequiredLabelRule: DefaultProgramBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultProgramBaseline) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultProgramBaselineRequiredCodeRule: DefaultProgramBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultProgramBaseline) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultProgramBaselineGraceDaysRangeRule: DefaultProgramBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultProgramBaseline) -> [String] {
            let value = item.graceDays
            var problems: [String] = []
            if value < min {
                problems.append("grace days \(value) is below \(min)")
            }
            if value > max {
                problems.append("grace days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DefaultProgramBaselineActiveGuardRule: DefaultProgramBaselineRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: DefaultProgramBaseline) -> [String] {
            if item.active && (item.graceDays > limit) {
                return ["grace days \(item.graceDays) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class DefaultProgramBaselineLabelLengthRule: DefaultProgramBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultProgramBaseline) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a default program baseline.
    final class DefaultProgramBaselineValidator {
        var rules: [any DefaultProgramBaselineRule]

        init(rules: [any DefaultProgramBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultProgramBaseline) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultProgramBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultProgramBaseline]) -> [String: [String]] {
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

    static func defaultDefaultProgramBaselineValidator() -> DefaultProgramBaselineValidator {
        return DefaultProgramBaselineValidator(
            rules: [
                DefaultProgramBaselineCodePrefixRule(prefix: "REF"),
                DefaultProgramBaselineRequiredLabelRule(message: "default program baseline needs an entry"),
                DefaultProgramBaselineRequiredCodeRule(message: "default program baseline needs this field"),
                DefaultProgramBaselineGraceDaysRangeRule(min: 16, max: 32),
                DefaultProgramBaselineActiveGuardRule(limit: 64),
                DefaultProgramBaselineLabelLengthRule(maxLength: 64),
            ]
        )
    }
}
