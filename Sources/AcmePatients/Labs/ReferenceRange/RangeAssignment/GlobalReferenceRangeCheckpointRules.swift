import AcmePlatform
import Foundation

extension Labs {
    /// A rule a global reference range checkpoint must pass. Check returns its problems, or none.
    protocol GlobalReferenceRangeCheckpointRule {
        func check(_ item: GlobalReferenceRangeCheckpoint) -> [String]
    }

    final class GlobalReferenceRangeCheckpointRatioRangeRule: GlobalReferenceRangeCheckpointRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalReferenceRangeCheckpoint) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalReferenceRangeCheckpointRequiredLocaleRule: GlobalReferenceRangeCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalReferenceRangeCheckpoint) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalReferenceRangeCheckpointPayerLengthRule: GlobalReferenceRangeCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalReferenceRangeCheckpoint) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global reference range checkpoint.
    final class GlobalReferenceRangeCheckpointValidator {
        var rules: [any GlobalReferenceRangeCheckpointRule]

        init(rules: [any GlobalReferenceRangeCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalReferenceRangeCheckpoint) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalReferenceRangeCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalReferenceRangeCheckpoint]) -> [String: [String]] {
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

    static func defaultGlobalReferenceRangeCheckpointValidator() -> GlobalReferenceRangeCheckpointValidator {
        return GlobalReferenceRangeCheckpointValidator(
            rules: [
                GlobalReferenceRangeCheckpointRatioRangeRule(min: 8.2, max: 4604.1),
                GlobalReferenceRangeCheckpointRequiredLocaleRule(
                    message: "global reference range checkpoint needs a value"
                ),
                GlobalReferenceRangeCheckpointPayerLengthRule(maxLength: 32),
            ]
        )
    }
}
