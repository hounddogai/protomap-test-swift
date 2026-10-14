import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a primary acuity plan score must pass. Check returns its problems, or none.
    protocol PrimaryAcuityPlanScoreRule {
        func check(_ item: PrimaryAcuityPlanScore) -> [String]
    }

    final class PrimaryAcuityPlanScoreCodeLengthRule: PrimaryAcuityPlanScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryAcuityPlanScore) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryAcuityPlanScoreRequiredTitleRule: PrimaryAcuityPlanScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryAcuityPlanScore) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryAcuityPlanScoreMarginRangeRule: PrimaryAcuityPlanScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryAcuityPlanScore) -> [String] {
            let value = item.margin
            var problems: [String] = []
            if value < min {
                problems.append("margin \(value) is below \(min)")
            }
            if value > max {
                problems.append("margin \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a primary acuity plan score.
    final class PrimaryAcuityPlanScoreValidator {
        var rules: [any PrimaryAcuityPlanScoreRule]

        init(rules: [any PrimaryAcuityPlanScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryAcuityPlanScore) -> [String] {
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

        func requireValid(_ item: PrimaryAcuityPlanScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryAcuityPlanScore]) -> [String: [String]] {
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

    static func defaultPrimaryAcuityPlanScoreValidator() -> PrimaryAcuityPlanScoreValidator {
        return PrimaryAcuityPlanScoreValidator(
            rules: [
                PrimaryAcuityPlanScoreCodeLengthRule(maxLength: 120),
                PrimaryAcuityPlanScoreRequiredTitleRule(message: "primary acuity plan score needs a value"),
                PrimaryAcuityPlanScoreMarginRangeRule(min: 5.4, max: 2539.9),
            ]
        )
    }
}
