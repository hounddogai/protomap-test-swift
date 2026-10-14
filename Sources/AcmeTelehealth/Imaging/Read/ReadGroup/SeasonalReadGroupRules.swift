import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a seasonal read group must pass. Check returns its problems, or none.
    protocol SeasonalReadGroupRule {
        func check(_ item: SeasonalReadGroup) -> [String]
    }

    final class SeasonalReadGroupRequiredCodeRule: SeasonalReadGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalReadGroup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalReadGroupCodeLengthRule: SeasonalReadGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalReadGroup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalReadGroupCodePrefixRule: SeasonalReadGroupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SeasonalReadGroup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SeasonalReadGroupLabelLengthRule: SeasonalReadGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalReadGroup) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalReadGroupScoreRangeRule: SeasonalReadGroupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalReadGroup) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalReadGroupRequiredLabelRule: SeasonalReadGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalReadGroup) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal read group.
    final class SeasonalReadGroupValidator {
        var rules: [any SeasonalReadGroupRule]

        init(rules: [any SeasonalReadGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalReadGroup) -> [String] {
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

        func requireValid(_ item: SeasonalReadGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalReadGroup]) -> [String: [String]] {
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

    static func defaultSeasonalReadGroupValidator() -> SeasonalReadGroupValidator {
        return SeasonalReadGroupValidator(
            rules: [
                SeasonalReadGroupRequiredCodeRule(message: "seasonal read group needs a value"),
                SeasonalReadGroupCodeLengthRule(maxLength: 32),
                SeasonalReadGroupCodePrefixRule(prefix: "OPS"),
                SeasonalReadGroupLabelLengthRule(maxLength: 86400),
                SeasonalReadGroupScoreRangeRule(min: 7.2, max: 4639.4),
                SeasonalReadGroupRequiredLabelRule(message: "seasonal read group needs this field"),
            ]
        )
    }
}
