import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a seasonal bed board preference must pass. Check returns its problems, or none.
    protocol SeasonalBedBoardPreferenceRule {
        func check(_ item: SeasonalBedBoardPreference) -> [String]
    }

    final class SeasonalBedBoardPreferenceTagsLimitRule: SeasonalBedBoardPreferenceRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: SeasonalBedBoardPreference) -> [String] {
            var problems: [String] = []
            if item.tags.count > maxCount {
                problems.append("has \(item.tags.count) tags, at most \(maxCount) allowed")
            }
            for tag in item.tags {
                if banned.contains(tag) {
                    problems.append("tag \(tag) is not allowed")
                }
            }
            return problems
        }
    }

    final class SeasonalBedBoardPreferenceRequiredLabelRule: SeasonalBedBoardPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalBedBoardPreference) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalBedBoardPreferenceRequiredTitleRule: SeasonalBedBoardPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalBedBoardPreference) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal bed board preference.
    final class SeasonalBedBoardPreferenceValidator {
        var rules: [any SeasonalBedBoardPreferenceRule]

        init(rules: [any SeasonalBedBoardPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalBedBoardPreference) -> [String] {
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

        func requireValid(_ item: SeasonalBedBoardPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalBedBoardPreference]) -> [String: [String]] {
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

    static func defaultSeasonalBedBoardPreferenceValidator() -> SeasonalBedBoardPreferenceValidator {
        return SeasonalBedBoardPreferenceValidator(
            rules: [
                SeasonalBedBoardPreferenceTagsLimitRule(maxCount: 32, banned: ["manual", "lenient"]),
                SeasonalBedBoardPreferenceRequiredLabelRule(message: "seasonal bed board preference needs an entry"),
                SeasonalBedBoardPreferenceRequiredTitleRule(message: "seasonal bed board preference needs this field"),
            ]
        )
    }
}
