import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a manual recall score must pass. Check returns its problems, or none.
    protocol ManualRecallScoreRule {
        func check(_ item: ManualRecallScore) -> [String]
    }

    final class ManualRecallScoreCodePrefixRule: ManualRecallScoreRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualRecallScore) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ManualRecallScoreRatioRangeRule: ManualRecallScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualRecallScore) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ManualRecallScoreRequiredUnitRule: ManualRecallScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualRecallScore) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualRecallScoreUnitLengthRule: ManualRecallScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualRecallScore) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual recall score.
    final class ManualRecallScoreValidator {
        var rules: [any ManualRecallScoreRule]

        init(rules: [any ManualRecallScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualRecallScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualRecallScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualRecallScore]) -> [String: [String]] {
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

    static func defaultManualRecallScoreValidator() -> ManualRecallScoreValidator {
        return ManualRecallScoreValidator(
            rules: [
                ManualRecallScoreCodePrefixRule(prefix: "REF"),
                ManualRecallScoreRatioRangeRule(min: 3.1, max: 106.0),
                ManualRecallScoreRequiredUnitRule(message: "manual recall score needs a value"),
                ManualRecallScoreUnitLengthRule(maxLength: 120),
            ]
        )
    }
}
