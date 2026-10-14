import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a legacy risk score entry must pass. Check returns its problems, or none.
    protocol LegacyRiskScoreEntryRule {
        func check(_ item: LegacyRiskScoreEntry) -> [String]
    }

    final class LegacyRiskScoreEntryRequiredTitleRule: LegacyRiskScoreEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyRiskScoreEntry) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyRiskScoreEntryWindowDaysRangeRule: LegacyRiskScoreEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyRiskScoreEntry) -> [String] {
            let value = item.windowDays
            var problems: [String] = []
            if value < min {
                problems.append("window days \(value) is below \(min)")
            }
            if value > max {
                problems.append("window days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LegacyRiskScoreEntryWeightRangeRule: LegacyRiskScoreEntryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyRiskScoreEntry) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy risk score entry.
    final class LegacyRiskScoreEntryValidator {
        var rules: [any LegacyRiskScoreEntryRule]

        init(rules: [any LegacyRiskScoreEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyRiskScoreEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyRiskScoreEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyRiskScoreEntry]) -> [String: [String]] {
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

    static func defaultLegacyRiskScoreEntryValidator() -> LegacyRiskScoreEntryValidator {
        return LegacyRiskScoreEntryValidator(
            rules: [
                LegacyRiskScoreEntryRequiredTitleRule(message: "legacy risk score entry needs an entry"),
                LegacyRiskScoreEntryWindowDaysRangeRule(min: 32, max: 86400),
                LegacyRiskScoreEntryWeightRangeRule(min: 4.8, max: 2869.3),
            ]
        )
    }
}
