import AcmePlatform
import Foundation

extension Labs {
    /// A rule a specimen override must pass. Check returns its problems, or none.
    protocol SpecimenOverrideRule {
        func check(_ item: SpecimenOverride) -> [String]
    }

    final class SpecimenOverrideAllowedTitleRule: SpecimenOverrideRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SpecimenOverride) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is expired"]
            }
            return []
        }
    }

    final class SpecimenOverrideNotesLengthRule: SpecimenOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SpecimenOverride) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SpecimenOverrideAcuityRangeRule: SpecimenOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SpecimenOverride) -> [String] {
            let value = item.acuity
            var problems: [String] = []
            if value < min {
                problems.append("acuity \(value) is below \(min)")
            }
            if value > max {
                problems.append("acuity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SpecimenOverrideLocaleLengthRule: SpecimenOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SpecimenOverride) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SpecimenOverrideTitleLengthRule: SpecimenOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SpecimenOverride) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SpecimenOverrideRequiredNotesRule: SpecimenOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SpecimenOverride) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a specimen override.
    final class SpecimenOverrideValidator {
        var rules: [any SpecimenOverrideRule]

        init(rules: [any SpecimenOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: SpecimenOverride) -> [String] {
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

        func requireValid(_ item: SpecimenOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SpecimenOverride]) -> [String: [String]] {
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

    static func defaultSpecimenOverrideValidator() -> SpecimenOverrideValidator {
        return SpecimenOverrideValidator(
            rules: [
                SpecimenOverrideAllowedTitleRule(allowed: ["scheduled"]),
                SpecimenOverrideNotesLengthRule(maxLength: 120),
                SpecimenOverrideAcuityRangeRule(min: 32, max: 80),
                SpecimenOverrideLocaleLengthRule(maxLength: 80),
                SpecimenOverrideTitleLengthRule(maxLength: 80),
                SpecimenOverrideRequiredNotesRule(message: "specimen override needs a value"),
            ]
        )
    }
}
