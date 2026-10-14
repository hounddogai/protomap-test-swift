import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a skill mix reservation must pass. Check returns its problems, or none.
    protocol SkillMixReservationRule {
        func check(_ item: SkillMixReservation) -> [String]
    }

    final class SkillMixReservationRequiredTitleRule: SkillMixReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SkillMixReservation) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SkillMixReservationRequiredLabelRule: SkillMixReservationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SkillMixReservation) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SkillMixReservationTitleLengthRule: SkillMixReservationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SkillMixReservation) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a skill mix reservation.
    final class SkillMixReservationValidator {
        var rules: [any SkillMixReservationRule]

        init(rules: [any SkillMixReservationRule]) {
            self.rules = rules
        }

        func validate(_ item: SkillMixReservation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SkillMixReservation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SkillMixReservation]) -> [String: [String]] {
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

    static func defaultSkillMixReservationValidator() -> SkillMixReservationValidator {
        return SkillMixReservationValidator(
            rules: [
                SkillMixReservationRequiredTitleRule(message: "skill mix reservation needs an entry"),
                SkillMixReservationRequiredLabelRule(message: "skill mix reservation needs a value"),
                SkillMixReservationTitleLengthRule(maxLength: 80),
            ]
        )
    }
}
