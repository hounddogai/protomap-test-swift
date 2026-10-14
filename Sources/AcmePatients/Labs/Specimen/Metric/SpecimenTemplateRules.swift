import AcmePlatform
import Foundation

extension Labs {
    /// A rule a specimen template must pass. Check returns its problems, or none.
    protocol SpecimenTemplateRule {
        func check(_ item: SpecimenTemplate) -> [String]
    }

    final class SpecimenTemplateRequiredFacilityRule: SpecimenTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SpecimenTemplate) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SpecimenTemplateFacilityLengthRule: SpecimenTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SpecimenTemplate) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SpecimenTemplateRequiredTitleRule: SpecimenTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SpecimenTemplate) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SpecimenTemplateStartsAtRangeRule: SpecimenTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SpecimenTemplate) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SpecimenTemplateSpecialtyLengthRule: SpecimenTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SpecimenTemplate) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SpecimenTemplateRevisionRangeRule: SpecimenTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SpecimenTemplate) -> [String] {
            let value = item.revision
            var problems: [String] = []
            if value < min {
                problems.append("revision \(value) is below \(min)")
            }
            if value > max {
                problems.append("revision \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a specimen template.
    final class SpecimenTemplateValidator {
        var rules: [any SpecimenTemplateRule]

        init(rules: [any SpecimenTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: SpecimenTemplate) -> [String] {
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

        func requireValid(_ item: SpecimenTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SpecimenTemplate]) -> [String: [String]] {
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

    static func defaultSpecimenTemplateValidator() -> SpecimenTemplateValidator {
        return SpecimenTemplateValidator(
            rules: [
                SpecimenTemplateRequiredFacilityRule(message: "specimen template needs a value"),
                SpecimenTemplateFacilityLengthRule(maxLength: 64),
                SpecimenTemplateRequiredTitleRule(message: "specimen template needs this field"),
                SpecimenTemplateStartsAtRangeRule(min: 120, max: 3600),
                SpecimenTemplateSpecialtyLengthRule(maxLength: 1000),
                SpecimenTemplateRevisionRangeRule(min: 16, max: 86400),
            ]
        )
    }
}
