import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a seasonal read exception must pass. Check returns its problems, or none.
    protocol SeasonalReadExceptionRule {
        func check(_ item: SeasonalReadException) -> [String]
    }

    final class SeasonalReadExceptionCodePrefixRule: SeasonalReadExceptionRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SeasonalReadException) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SeasonalReadExceptionRetriesRangeRule: SeasonalReadExceptionRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalReadException) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SeasonalReadExceptionAllowedCodeRule: SeasonalReadExceptionRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalReadException) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is too long"]
            }
            return []
        }
    }

    final class SeasonalReadExceptionLabelLengthRule: SeasonalReadExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalReadException) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalReadExceptionRequiredNotesRule: SeasonalReadExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalReadException) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal read exception.
    final class SeasonalReadExceptionValidator {
        var rules: [any SeasonalReadExceptionRule]

        init(rules: [any SeasonalReadExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalReadException) -> [String] {
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

        func requireValid(_ item: SeasonalReadException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalReadException]) -> [String: [String]] {
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

    static func defaultSeasonalReadExceptionValidator() -> SeasonalReadExceptionValidator {
        return SeasonalReadExceptionValidator(
            rules: [
                SeasonalReadExceptionCodePrefixRule(prefix: "OPS"),
                SeasonalReadExceptionRetriesRangeRule(min: 80, max: 3600),
                SeasonalReadExceptionAllowedCodeRule(allowed: ["manual", "legacy", "seasonal"]),
                SeasonalReadExceptionLabelLengthRule(maxLength: 120),
                SeasonalReadExceptionRequiredNotesRule(message: "seasonal read exception needs a value"),
            ]
        )
    }
}
