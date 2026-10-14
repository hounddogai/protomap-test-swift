import AcmePlatform
import Foundation

extension Consent {
    /// A rule a language checkpoint must pass. Check returns its problems, or none.
    protocol LanguageCheckpointRule {
        func check(_ item: LanguageCheckpoint) -> [String]
    }

    final class LanguageCheckpointChannelLengthRule: LanguageCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LanguageCheckpoint) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LanguageCheckpointDosageMgRangeRule: LanguageCheckpointRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LanguageCheckpoint) -> [String] {
            let value = item.dosageMg
            var problems: [String] = []
            if value < min {
                problems.append("dosage mg \(value) is below \(min)")
            }
            if value > max {
                problems.append("dosage mg \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LanguageCheckpointRefillsRangeRule: LanguageCheckpointRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LanguageCheckpoint) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a language checkpoint.
    final class LanguageCheckpointValidator {
        var rules: [any LanguageCheckpointRule]

        init(rules: [any LanguageCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: LanguageCheckpoint) -> [String] {
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

        func requireValid(_ item: LanguageCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LanguageCheckpoint]) -> [String: [String]] {
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

    static func defaultLanguageCheckpointValidator() -> LanguageCheckpointValidator {
        return LanguageCheckpointValidator(
            rules: [
                LanguageCheckpointChannelLengthRule(maxLength: 16),
                LanguageCheckpointDosageMgRangeRule(min: 0.7, max: 4725.9),
                LanguageCheckpointRefillsRangeRule(min: 80, max: 120),
            ]
        )
    }
}
