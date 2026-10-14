import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a recall score must pass. Check returns its problems, or none.
    protocol RecallScoreRule {
        func check(_ item: RecallScore) -> [String]
    }

    final class RecallScoreCodePrefixRule: RecallScoreRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RecallScore) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RecallScoreRatioRangeRule: RecallScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RecallScore) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RecallScoreRequiredLabelRule: RecallScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RecallScore) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RecallScoreRequiredPayerRule: RecallScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RecallScore) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a recall score.
    final class RecallScoreValidator {
        var rules: [any RecallScoreRule]

        init(rules: [any RecallScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: RecallScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RecallScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RecallScore]) -> [String: [String]] {
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

    static func defaultRecallScoreValidator() -> RecallScoreValidator {
        return RecallScoreValidator(
            rules: [
                RecallScoreCodePrefixRule(prefix: "OPS"),
                RecallScoreRatioRangeRule(min: 9.2, max: 1939.4),
                RecallScoreRequiredLabelRule(message: "recall score needs a value"),
                RecallScoreRequiredPayerRule(message: "recall score needs a value"),
            ]
        )
    }
}
