import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a tiered modality profile must pass. Check returns its problems, or none.
    protocol TieredModalityProfileRule {
        func check(_ item: TieredModalityProfile) -> [String]
    }

    final class TieredModalityProfileAllowedNameRule: TieredModalityProfileRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredModalityProfile) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is duplicated"]
            }
            return []
        }
    }

    final class TieredModalityProfileBudgetRangeRule: TieredModalityProfileRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredModalityProfile) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredModalityProfileCodeLengthRule: TieredModalityProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredModalityProfile) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredModalityProfileRequiredLabelRule: TieredModalityProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredModalityProfile) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredModalityProfileNameLengthRule: TieredModalityProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredModalityProfile) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered modality profile.
    final class TieredModalityProfileValidator {
        var rules: [any TieredModalityProfileRule]

        init(rules: [any TieredModalityProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredModalityProfile) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredModalityProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredModalityProfile]) -> [String: [String]] {
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

    static func defaultTieredModalityProfileValidator() -> TieredModalityProfileValidator {
        return TieredModalityProfileValidator(
            rules: [
                TieredModalityProfileAllowedNameRule(allowed: ["regional"]),
                TieredModalityProfileBudgetRangeRule(min: 1.8, max: 3097.0),
                TieredModalityProfileCodeLengthRule(maxLength: 1000),
                TieredModalityProfileRequiredLabelRule(message: "tiered modality profile needs an entry"),
                TieredModalityProfileNameLengthRule(maxLength: 1000),
            ]
        )
    }
}
