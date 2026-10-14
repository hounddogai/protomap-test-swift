import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a lenient skill mix assignment must pass. Check returns its problems, or none.
    protocol LenientSkillMixAssignmentRule {
        func check(_ item: LenientSkillMixAssignment) -> [String]
    }

    final class LenientSkillMixAssignmentUnitLengthRule: LenientSkillMixAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientSkillMixAssignment) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientSkillMixAssignmentRequiredUnitRule: LenientSkillMixAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientSkillMixAssignment) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientSkillMixAssignmentAllowedCodeRule: LenientSkillMixAssignmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LenientSkillMixAssignment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is not allowed"]
            }
            return []
        }
    }

    final class LenientSkillMixAssignmentRequiredPatientRefRule: LenientSkillMixAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientSkillMixAssignment) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a lenient skill mix assignment.
    final class LenientSkillMixAssignmentValidator {
        var rules: [any LenientSkillMixAssignmentRule]

        init(rules: [any LenientSkillMixAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientSkillMixAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientSkillMixAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientSkillMixAssignment]) -> [String: [String]] {
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

    static func defaultLenientSkillMixAssignmentValidator() -> LenientSkillMixAssignmentValidator {
        return LenientSkillMixAssignmentValidator(
            rules: [
                LenientSkillMixAssignmentUnitLengthRule(maxLength: 64),
                LenientSkillMixAssignmentRequiredUnitRule(message: "lenient skill mix assignment needs a value"),
                LenientSkillMixAssignmentAllowedCodeRule(allowed: ["lenient", "scheduled", "tiered"]),
                LenientSkillMixAssignmentRequiredPatientRefRule(
                    message: "lenient skill mix assignment needs this field"
                ),
            ]
        )
    }
}
