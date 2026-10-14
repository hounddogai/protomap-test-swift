import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a acuity plan score must pass. Check returns its problems, or none.
    protocol AcuityPlanScoreRule {
        func check(_ item: AcuityPlanScore) -> [String]
    }

    final class AcuityPlanScoreRequiredUnitRule: AcuityPlanScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AcuityPlanScore) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AcuityPlanScoreRequiredNameRule: AcuityPlanScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AcuityPlanScore) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AcuityPlanScoreRateRangeRule: AcuityPlanScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AcuityPlanScore) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AcuityPlanScoreUnitLengthRule: AcuityPlanScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanScore) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AcuityPlanScoreNameLengthRule: AcuityPlanScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanScore) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a acuity plan score.
    final class AcuityPlanScoreValidator {
        var rules: [any AcuityPlanScoreRule]

        init(rules: [any AcuityPlanScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: AcuityPlanScore) -> [String] {
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

        func requireValid(_ item: AcuityPlanScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AcuityPlanScore]) -> [String: [String]] {
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

    static func defaultAcuityPlanScoreValidator() -> AcuityPlanScoreValidator {
        return AcuityPlanScoreValidator(
            rules: [
                AcuityPlanScoreRequiredUnitRule(message: "acuity plan score needs this field"),
                AcuityPlanScoreRequiredNameRule(message: "acuity plan score needs a value"),
                AcuityPlanScoreRateRangeRule(min: 4.1, max: 3558.1),
                AcuityPlanScoreUnitLengthRule(maxLength: 80),
                AcuityPlanScoreNameLengthRule(maxLength: 64),
            ]
        )
    }
}
