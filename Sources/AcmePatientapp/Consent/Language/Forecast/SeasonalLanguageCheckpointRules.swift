import AcmePlatform
import Foundation

extension Consent {
    /// A rule a seasonal language checkpoint must pass. Check returns its problems, or none.
    protocol SeasonalLanguageCheckpointRule {
        func check(_ item: SeasonalLanguageCheckpoint) -> [String]
    }

    final class SeasonalLanguageCheckpointVersionRangeRule: SeasonalLanguageCheckpointRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalLanguageCheckpoint) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalLanguageCheckpointRequiredTitleRule: SeasonalLanguageCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalLanguageCheckpoint) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalLanguageCheckpointCodeLengthRule: SeasonalLanguageCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalLanguageCheckpoint) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalLanguageCheckpointAllowedCodeRule: SeasonalLanguageCheckpointRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalLanguageCheckpoint) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is above maximum"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal language checkpoint.
    final class SeasonalLanguageCheckpointValidator {
        var rules: [any SeasonalLanguageCheckpointRule]

        init(rules: [any SeasonalLanguageCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalLanguageCheckpoint) -> [String] {
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

        func requireValid(_ item: SeasonalLanguageCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalLanguageCheckpoint]) -> [String: [String]] {
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

    static func defaultSeasonalLanguageCheckpointValidator() -> SeasonalLanguageCheckpointValidator {
        return SeasonalLanguageCheckpointValidator(
            rules: [
                SeasonalLanguageCheckpointVersionRangeRule(min: 32, max: 255),
                SeasonalLanguageCheckpointRequiredTitleRule(message: "seasonal language checkpoint needs this field"),
                SeasonalLanguageCheckpointCodeLengthRule(maxLength: 3600),
                SeasonalLanguageCheckpointAllowedCodeRule(allowed: ["global", "legacy"]),
            ]
        )
    }
}
