import AcmePlatform
import Foundation

extension Labs {
    /// A rule a weighted specimen milestone must pass. Check returns its problems, or none.
    protocol WeightedSpecimenMilestoneRule {
        func check(_ item: WeightedSpecimenMilestone) -> [String]
    }

    final class WeightedSpecimenMilestoneRequiredCodeRule: WeightedSpecimenMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedSpecimenMilestone) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedSpecimenMilestoneRequiredDiagnosisCodeRule: WeightedSpecimenMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedSpecimenMilestone) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedSpecimenMilestoneNameLengthRule: WeightedSpecimenMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedSpecimenMilestone) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedSpecimenMilestoneRequiredPatientRefRule: WeightedSpecimenMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedSpecimenMilestone) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedSpecimenMilestoneScoreRangeRule: WeightedSpecimenMilestoneRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedSpecimenMilestone) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a weighted specimen milestone.
    final class WeightedSpecimenMilestoneValidator {
        var rules: [any WeightedSpecimenMilestoneRule]

        init(rules: [any WeightedSpecimenMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedSpecimenMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedSpecimenMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedSpecimenMilestone]) -> [String: [String]] {
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

    static func defaultWeightedSpecimenMilestoneValidator() -> WeightedSpecimenMilestoneValidator {
        return WeightedSpecimenMilestoneValidator(
            rules: [
                WeightedSpecimenMilestoneRequiredCodeRule(message: "weighted specimen milestone needs this field"),
                WeightedSpecimenMilestoneRequiredDiagnosisCodeRule(
                    message: "weighted specimen milestone needs this field"
                ),
                WeightedSpecimenMilestoneNameLengthRule(maxLength: 3600),
                WeightedSpecimenMilestoneRequiredPatientRefRule(
                    message: "weighted specimen milestone needs this field"
                ),
                WeightedSpecimenMilestoneScoreRangeRule(min: 8.6, max: 68.0),
            ]
        )
    }
}
