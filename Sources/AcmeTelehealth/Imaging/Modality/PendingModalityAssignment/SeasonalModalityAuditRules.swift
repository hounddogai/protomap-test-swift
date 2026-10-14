import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a seasonal modality audit must pass. Check returns its problems, or none.
    protocol SeasonalModalityAuditRule {
        func check(_ item: SeasonalModalityAudit) -> [String]
    }

    final class SeasonalModalityAuditRequiredCodeRule: SeasonalModalityAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalModalityAudit) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalModalityAuditAmountRangeRule: SeasonalModalityAuditRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalModalityAudit) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SeasonalModalityAuditAllowedTitleRule: SeasonalModalityAuditRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalModalityAudit) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is below minimum"]
            }
            return []
        }
    }

    final class SeasonalModalityAuditRequiredAllergyRule: SeasonalModalityAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalModalityAudit) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalModalityAuditAttemptsRangeRule: SeasonalModalityAuditRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalModalityAudit) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SeasonalModalityAuditTitleLengthRule: SeasonalModalityAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalModalityAudit) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal modality audit.
    final class SeasonalModalityAuditValidator {
        var rules: [any SeasonalModalityAuditRule]

        init(rules: [any SeasonalModalityAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalModalityAudit) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalModalityAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalModalityAudit]) -> [String: [String]] {
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

    static func defaultSeasonalModalityAuditValidator() -> SeasonalModalityAuditValidator {
        return SeasonalModalityAuditValidator(
            rules: [
                SeasonalModalityAuditRequiredCodeRule(message: "seasonal modality audit needs a value"),
                SeasonalModalityAuditAmountRangeRule(min: 7.4, max: 1495.9),
                SeasonalModalityAuditAllowedTitleRule(allowed: ["legacy"]),
                SeasonalModalityAuditRequiredAllergyRule(message: "seasonal modality audit needs an entry"),
                SeasonalModalityAuditAttemptsRangeRule(min: 32, max: 80),
                SeasonalModalityAuditTitleLengthRule(maxLength: 16),
            ]
        )
    }
}
