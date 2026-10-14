import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a skill mix window must pass. Check returns its problems, or none.
    protocol SkillMixWindowRule {
        func check(_ item: SkillMixWindow) -> [String]
    }

    final class SkillMixWindowSourceLengthRule: SkillMixWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SkillMixWindow) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SkillMixWindowClinicianIDLengthRule: SkillMixWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SkillMixWindow) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SkillMixWindowTitleLengthRule: SkillMixWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SkillMixWindow) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SkillMixWindowCodePrefixRule: SkillMixWindowRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SkillMixWindow) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SkillMixWindowCostRangeRule: SkillMixWindowRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SkillMixWindow) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SkillMixWindowRequiredCodeRule: SkillMixWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SkillMixWindow) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a skill mix window.
    final class SkillMixWindowValidator {
        var rules: [any SkillMixWindowRule]

        init(rules: [any SkillMixWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: SkillMixWindow) -> [String] {
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

        func requireValid(_ item: SkillMixWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SkillMixWindow]) -> [String: [String]] {
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

    static func defaultSkillMixWindowValidator() -> SkillMixWindowValidator {
        return SkillMixWindowValidator(
            rules: [
                SkillMixWindowSourceLengthRule(maxLength: 86400),
                SkillMixWindowClinicianIDLengthRule(maxLength: 3600),
                SkillMixWindowTitleLengthRule(maxLength: 32),
                SkillMixWindowCodePrefixRule(prefix: "REF"),
                SkillMixWindowCostRangeRule(min: 4.5, max: 1051.0),
                SkillMixWindowRequiredCodeRule(message: "skill mix window needs this field"),
            ]
        )
    }
}
