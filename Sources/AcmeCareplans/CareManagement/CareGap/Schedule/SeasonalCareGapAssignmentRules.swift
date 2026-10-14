import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a seasonal care gap assignment must pass. Check returns its problems, or none.
    protocol SeasonalCareGapAssignmentRule {
        func check(_ item: SeasonalCareGapAssignment) -> [String]
    }

    final class SeasonalCareGapAssignmentAllowedNameRule: SeasonalCareGapAssignmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalCareGapAssignment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is below minimum"]
            }
            return []
        }
    }

    final class SeasonalCareGapAssignmentCeilingRangeRule: SeasonalCareGapAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalCareGapAssignment) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SeasonalCareGapAssignmentCodePrefixRule: SeasonalCareGapAssignmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SeasonalCareGapAssignment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SeasonalCareGapAssignmentAcuityRangeRule: SeasonalCareGapAssignmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalCareGapAssignment) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalCareGapAssignmentExpiresAtRangeRule: SeasonalCareGapAssignmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalCareGapAssignment) -> [String] {
            let value = item.expiresAt
            var problems: [String] = []
            if value < min {
                problems.append("expires at \(value) is below \(min)")
            }
            if value > max {
                problems.append("expires at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a seasonal care gap assignment.
    final class SeasonalCareGapAssignmentValidator {
        var rules: [any SeasonalCareGapAssignmentRule]

        init(rules: [any SeasonalCareGapAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalCareGapAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalCareGapAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalCareGapAssignment]) -> [String: [String]] {
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

    static func defaultSeasonalCareGapAssignmentValidator() -> SeasonalCareGapAssignmentValidator {
        return SeasonalCareGapAssignmentValidator(
            rules: [
                SeasonalCareGapAssignmentAllowedNameRule(allowed: []),
                SeasonalCareGapAssignmentCeilingRangeRule(min: 0.8, max: 2660.1),
                SeasonalCareGapAssignmentCodePrefixRule(prefix: "X"),
                SeasonalCareGapAssignmentAcuityRangeRule(min: 120, max: 86400),
                SeasonalCareGapAssignmentExpiresAtRangeRule(min: 64, max: 86400),
            ]
        )
    }
}
