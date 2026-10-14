import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a bed board preference must pass. Check returns its problems, or none.
    protocol BedBoardPreferenceRule {
        func check(_ item: BedBoardPreference) -> [String]
    }

    final class BedBoardPreferenceRequiredCodeRule: BedBoardPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BedBoardPreference) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BedBoardPreferenceGraceDaysRangeRule: BedBoardPreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BedBoardPreference) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BedBoardPreferenceTitleLengthRule: BedBoardPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BedBoardPreference) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a bed board preference.
    final class BedBoardPreferenceValidator {
        var rules: [any BedBoardPreferenceRule]

        init(rules: [any BedBoardPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: BedBoardPreference) -> [String] {
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

        func requireValid(_ item: BedBoardPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BedBoardPreference]) -> [String: [String]] {
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

    static func defaultBedBoardPreferenceValidator() -> BedBoardPreferenceValidator {
        return BedBoardPreferenceValidator(
            rules: [
                BedBoardPreferenceRequiredCodeRule(message: "bed board preference needs this field"),
                BedBoardPreferenceGraceDaysRangeRule(min: 16, max: 3600),
                BedBoardPreferenceTitleLengthRule(maxLength: 16),
            ]
        )
    }
}
