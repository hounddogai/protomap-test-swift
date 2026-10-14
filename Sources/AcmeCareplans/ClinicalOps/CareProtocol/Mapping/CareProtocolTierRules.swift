import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a care protocol tier must pass. Check returns its problems, or none.
    protocol CareProtocolTierRule {
        func check(_ item: CareProtocolTier) -> [String]
    }

    final class CareProtocolTierRequiredCodeRule: CareProtocolTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolTier) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolTierRequiredTitleRule: CareProtocolTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolTier) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolTierVersionRangeRule: CareProtocolTierRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolTier) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CareProtocolTierAllowedNotesRule: CareProtocolTierRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CareProtocolTier) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.notes)) {
                return ["notes \(item.notes) is missing"]
            }
            return []
        }
    }

    final class CareProtocolTierCostRangeRule: CareProtocolTierRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolTier) -> [String] {
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

    final class CareProtocolTierRatioRangeRule: CareProtocolTierRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolTier) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a care protocol tier.
    final class CareProtocolTierValidator {
        var rules: [any CareProtocolTierRule]

        init(rules: [any CareProtocolTierRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolTier) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CareProtocolTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolTier]) -> [String: [String]] {
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

    static func defaultCareProtocolTierValidator() -> CareProtocolTierValidator {
        return CareProtocolTierValidator(
            rules: [
                CareProtocolTierRequiredCodeRule(message: "care protocol tier needs an entry"),
                CareProtocolTierRequiredTitleRule(message: "care protocol tier needs a value"),
                CareProtocolTierVersionRangeRule(min: 255, max: 86400),
                CareProtocolTierAllowedNotesRule(allowed: []),
                CareProtocolTierCostRangeRule(min: 7.5, max: 2266.1),
                CareProtocolTierRatioRangeRule(min: 3.3, max: 2770.2),
            ]
        )
    }
}
