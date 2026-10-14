import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a default formulary record must pass. Check returns its problems, or none.
    protocol DefaultFormularyRecordRule {
        func check(_ item: DefaultFormularyRecord) -> [String]
    }

    final class DefaultFormularyRecordRequiredNameRule: DefaultFormularyRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultFormularyRecord) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultFormularyRecordCodePrefixRule: DefaultFormularyRecordRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultFormularyRecord) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DefaultFormularyRecordSummaryLengthRule: DefaultFormularyRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultFormularyRecord) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultFormularyRecordExpiresAtRangeRule: DefaultFormularyRecordRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultFormularyRecord) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultFormularyRecordNameLengthRule: DefaultFormularyRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultFormularyRecord) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a default formulary record.
    final class DefaultFormularyRecordValidator {
        var rules: [any DefaultFormularyRecordRule]

        init(rules: [any DefaultFormularyRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultFormularyRecord) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultFormularyRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultFormularyRecord]) -> [String: [String]] {
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

    static func defaultDefaultFormularyRecordValidator() -> DefaultFormularyRecordValidator {
        return DefaultFormularyRecordValidator(
            rules: [
                DefaultFormularyRecordRequiredNameRule(message: "default formulary record needs a value"),
                DefaultFormularyRecordCodePrefixRule(prefix: "Q"),
                DefaultFormularyRecordSummaryLengthRule(maxLength: 32),
                DefaultFormularyRecordExpiresAtRangeRule(min: 16, max: 3600),
                DefaultFormularyRecordNameLengthRule(maxLength: 32),
            ]
        )
    }
}
