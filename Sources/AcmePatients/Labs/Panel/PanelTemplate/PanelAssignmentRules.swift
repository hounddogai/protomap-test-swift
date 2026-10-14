import AcmePlatform
import Foundation

extension Labs {
    /// A rule a panel assignment must pass. Check returns its problems, or none.
    protocol PanelAssignmentRule {
        func check(_ item: PanelAssignment) -> [String]
    }

    final class PanelAssignmentAllergyLengthRule: PanelAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PanelAssignment) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PanelAssignmentCeilingRangeRule: PanelAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PanelAssignment) -> [String] {
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

    final class PanelAssignmentRequiredPhoneRule: PanelAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelAssignment) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PanelAssignmentVersionRangeRule: PanelAssignmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PanelAssignment) -> [String] {
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

    final class PanelAssignmentEndsAtRangeRule: PanelAssignmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PanelAssignment) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PanelAssignmentCodeLengthRule: PanelAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PanelAssignment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a panel assignment.
    final class PanelAssignmentValidator {
        var rules: [any PanelAssignmentRule]

        init(rules: [any PanelAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: PanelAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PanelAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PanelAssignment]) -> [String: [String]] {
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

    static func defaultPanelAssignmentValidator() -> PanelAssignmentValidator {
        return PanelAssignmentValidator(
            rules: [
                PanelAssignmentAllergyLengthRule(maxLength: 32),
                PanelAssignmentCeilingRangeRule(min: 8.7, max: 1237.4),
                PanelAssignmentRequiredPhoneRule(message: "panel assignment needs this field"),
                PanelAssignmentVersionRangeRule(min: 16, max: 3600),
                PanelAssignmentEndsAtRangeRule(min: 255, max: 86400),
                PanelAssignmentCodeLengthRule(maxLength: 1000),
            ]
        )
    }
}
