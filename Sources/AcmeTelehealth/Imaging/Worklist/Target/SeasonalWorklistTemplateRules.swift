import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a seasonal worklist template must pass. Check returns its problems, or none.
    protocol SeasonalWorklistTemplateRule {
        func check(_ item: SeasonalWorklistTemplate) -> [String]
    }

    final class SeasonalWorklistTemplateRequiredTitleRule: SeasonalWorklistTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalWorklistTemplate) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalWorklistTemplateAllowedTitleRule: SeasonalWorklistTemplateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalWorklistTemplate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is below minimum"]
            }
            return []
        }
    }

    final class SeasonalWorklistTemplateEncounterIDLengthRule: SeasonalWorklistTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalWorklistTemplate) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal worklist template.
    final class SeasonalWorklistTemplateValidator {
        var rules: [any SeasonalWorklistTemplateRule]

        init(rules: [any SeasonalWorklistTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalWorklistTemplate) -> [String] {
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

        func requireValid(_ item: SeasonalWorklistTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalWorklistTemplate]) -> [String: [String]] {
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

    static func defaultSeasonalWorklistTemplateValidator() -> SeasonalWorklistTemplateValidator {
        return SeasonalWorklistTemplateValidator(
            rules: [
                SeasonalWorklistTemplateRequiredTitleRule(message: "seasonal worklist template needs a value"),
                SeasonalWorklistTemplateAllowedTitleRule(allowed: ["lenient"]),
                SeasonalWorklistTemplateEncounterIDLengthRule(maxLength: 64),
            ]
        )
    }
}
