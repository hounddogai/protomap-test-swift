import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a acuity plan assignment must pass. Check returns its problems, or none.
    protocol AcuityPlanAssignmentRule {
        func check(_ item: AcuityPlanAssignment) -> [String]
    }

    final class AcuityPlanAssignmentRatioRangeRule: AcuityPlanAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AcuityPlanAssignment) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AcuityPlanAssignmentCountryLengthRule: AcuityPlanAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanAssignment) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AcuityPlanAssignmentRequiredLabelRule: AcuityPlanAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AcuityPlanAssignment) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AcuityPlanAssignmentCodeLengthRule: AcuityPlanAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanAssignment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a acuity plan assignment.
    final class AcuityPlanAssignmentValidator {
        var rules: [any AcuityPlanAssignmentRule]

        init(rules: [any AcuityPlanAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: AcuityPlanAssignment) -> [String] {
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

        func requireValid(_ item: AcuityPlanAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AcuityPlanAssignment]) -> [String: [String]] {
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

    static func defaultAcuityPlanAssignmentValidator() -> AcuityPlanAssignmentValidator {
        return AcuityPlanAssignmentValidator(
            rules: [
                AcuityPlanAssignmentRatioRangeRule(min: 4.6, max: 3768.1),
                AcuityPlanAssignmentCountryLengthRule(maxLength: 16),
                AcuityPlanAssignmentRequiredLabelRule(message: "acuity plan assignment needs a value"),
                AcuityPlanAssignmentCodeLengthRule(maxLength: 80),
            ]
        )
    }
}
