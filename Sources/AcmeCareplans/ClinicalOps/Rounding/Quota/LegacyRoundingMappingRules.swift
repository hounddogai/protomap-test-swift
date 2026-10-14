import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a legacy rounding mapping must pass. Check returns its problems, or none.
    protocol LegacyRoundingMappingRule {
        func check(_ item: LegacyRoundingMapping) -> [String]
    }

    final class LegacyRoundingMappingPinnedGuardRule: LegacyRoundingMappingRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: LegacyRoundingMapping) -> [String] {
            if item.pinned && (item.cost > limit) {
                return ["cost \(item.cost) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class LegacyRoundingMappingRequiredCodeRule: LegacyRoundingMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyRoundingMapping) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyRoundingMappingCostRangeRule: LegacyRoundingMappingRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyRoundingMapping) -> [String] {
            let value = item.cost
            var problems: [String] = []
            if value < min {
                problems.append("cost \(value) is below \(min)")
            }
            if value > max {
                problems.append("cost \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LegacyRoundingMappingRequiredCategoryRule: LegacyRoundingMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyRoundingMapping) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyRoundingMappingRequiredEncounterIDRule: LegacyRoundingMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyRoundingMapping) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a legacy rounding mapping.
    final class LegacyRoundingMappingValidator {
        var rules: [any LegacyRoundingMappingRule]

        init(rules: [any LegacyRoundingMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyRoundingMapping) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyRoundingMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyRoundingMapping]) -> [String: [String]] {
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

    static func defaultLegacyRoundingMappingValidator() -> LegacyRoundingMappingValidator {
        return LegacyRoundingMappingValidator(
            rules: [
                LegacyRoundingMappingPinnedGuardRule(limit: 6.8),
                LegacyRoundingMappingRequiredCodeRule(message: "legacy rounding mapping needs this field"),
                LegacyRoundingMappingCostRangeRule(min: 7.7, max: 2467.6),
                LegacyRoundingMappingRequiredCategoryRule(message: "legacy rounding mapping needs this field"),
                LegacyRoundingMappingRequiredEncounterIDRule(message: "legacy rounding mapping needs this field"),
            ]
        )
    }
}
