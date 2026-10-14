import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a cleaning rollup must pass. Check returns its problems, or none.
    protocol CleaningRollupRule {
        func check(_ item: CleaningRollup) -> [String]
    }

    final class CleaningRollupRequiredLabelRule: CleaningRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningRollup) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CleaningRollupLabelLengthRule: CleaningRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CleaningRollup) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CleaningRollupCodePrefixRule: CleaningRollupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CleaningRollup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CleaningRollupCodeLengthRule: CleaningRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CleaningRollup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a cleaning rollup.
    final class CleaningRollupValidator {
        var rules: [any CleaningRollupRule]

        init(rules: [any CleaningRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: CleaningRollup) -> [String] {
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

        func requireValid(_ item: CleaningRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CleaningRollup]) -> [String: [String]] {
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

    static func defaultCleaningRollupValidator() -> CleaningRollupValidator {
        return CleaningRollupValidator(
            rules: [
                CleaningRollupRequiredLabelRule(message: "cleaning rollup needs this field"),
                CleaningRollupLabelLengthRule(maxLength: 16),
                CleaningRollupCodePrefixRule(prefix: "OPS"),
                CleaningRollupCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
