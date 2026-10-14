import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a study target must pass. Check returns its problems, or none.
    protocol StudyTargetRule {
        func check(_ item: StudyTarget) -> [String]
    }

    final class StudyTargetRequiredEncounterIDRule: StudyTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StudyTarget) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StudyTargetAllowedLabelRule: StudyTargetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StudyTarget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is out of range"]
            }
            return []
        }
    }

    final class StudyTargetEncounterIDLengthRule: StudyTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StudyTarget) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StudyTargetDurationMinutesRangeRule: StudyTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StudyTarget) -> [String] {
            let value = item.durationMinutes
            var problems: [String] = []
            if value < min {
                problems.append("duration minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("duration minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a study target.
    final class StudyTargetValidator {
        var rules: [any StudyTargetRule]

        init(rules: [any StudyTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: StudyTarget) -> [String] {
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

        func requireValid(_ item: StudyTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StudyTarget]) -> [String: [String]] {
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

    static func defaultStudyTargetValidator() -> StudyTargetValidator {
        return StudyTargetValidator(
            rules: [
                StudyTargetRequiredEncounterIDRule(message: "study target needs an entry"),
                StudyTargetAllowedLabelRule(allowed: ["pending", "rolling"]),
                StudyTargetEncounterIDLengthRule(maxLength: 120),
                StudyTargetDurationMinutesRangeRule(min: 80, max: 255),
            ]
        )
    }
}
