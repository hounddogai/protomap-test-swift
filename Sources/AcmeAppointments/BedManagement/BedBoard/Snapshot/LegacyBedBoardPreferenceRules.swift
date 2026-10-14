import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a legacy bed board preference must pass. Check returns its problems, or none.
    protocol LegacyBedBoardPreferenceRule {
        func check(_ item: LegacyBedBoardPreference) -> [String]
    }

    final class LegacyBedBoardPreferenceGraceDaysRangeRule: LegacyBedBoardPreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyBedBoardPreference) -> [String] {
            let value = item.graceDays
            var problems: [String] = []
            if value < min {
                problems.append("grace days \(value) is below \(min)")
            }
            if value > max {
                problems.append("grace days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LegacyBedBoardPreferenceAmountRangeRule: LegacyBedBoardPreferenceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyBedBoardPreference) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LegacyBedBoardPreferenceVersionRangeRule: LegacyBedBoardPreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyBedBoardPreference) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy bed board preference.
    final class LegacyBedBoardPreferenceValidator {
        var rules: [any LegacyBedBoardPreferenceRule]

        init(rules: [any LegacyBedBoardPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyBedBoardPreference) -> [String] {
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

        func requireValid(_ item: LegacyBedBoardPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyBedBoardPreference]) -> [String: [String]] {
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

    static func defaultLegacyBedBoardPreferenceValidator() -> LegacyBedBoardPreferenceValidator {
        return LegacyBedBoardPreferenceValidator(
            rules: [
                LegacyBedBoardPreferenceGraceDaysRangeRule(min: 32, max: 255),
                LegacyBedBoardPreferenceAmountRangeRule(min: 7.8, max: 2228.9),
                LegacyBedBoardPreferenceVersionRangeRule(min: 80, max: 3600),
            ]
        )
    }
}
