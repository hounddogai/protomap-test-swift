import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a care gap summary must pass. Check returns its problems, or none.
    protocol CareGapSummaryRule {
        func check(_ item: CareGapSummary) -> [String]
    }

    final class CareGapSummaryDescriptionLengthRule: CareGapSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareGapSummary) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareGapSummaryNotesLengthRule: CareGapSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareGapSummary) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareGapSummaryAllowedTitleRule: CareGapSummaryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CareGapSummary) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is duplicated"]
            }
            return []
        }
    }

    final class CareGapSummaryWeightRangeRule: CareGapSummaryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareGapSummary) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CareGapSummaryRequiredDescriptionRule: CareGapSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareGapSummary) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a care gap summary.
    final class CareGapSummaryValidator {
        var rules: [any CareGapSummaryRule]

        init(rules: [any CareGapSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: CareGapSummary) -> [String] {
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

        func requireValid(_ item: CareGapSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareGapSummary]) -> [String: [String]] {
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

    static func defaultCareGapSummaryValidator() -> CareGapSummaryValidator {
        return CareGapSummaryValidator(
            rules: [
                CareGapSummaryDescriptionLengthRule(maxLength: 1000),
                CareGapSummaryNotesLengthRule(maxLength: 32),
                CareGapSummaryAllowedTitleRule(allowed: []),
                CareGapSummaryWeightRangeRule(min: 7.4, max: 517.3),
                CareGapSummaryRequiredDescriptionRule(message: "care gap summary needs a value"),
            ]
        )
    }
}
