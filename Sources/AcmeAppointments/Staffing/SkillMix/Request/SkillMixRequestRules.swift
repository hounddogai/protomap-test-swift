import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a skill mix request must pass. Check returns its problems, or none.
    protocol SkillMixRequestRule {
        func check(_ item: SkillMixRequest) -> [String]
    }

    final class SkillMixRequestAllowedCategoryRule: SkillMixRequestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SkillMixRequest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.category)) {
                return ["category \(item.category) is missing"]
            }
            return []
        }
    }

    final class SkillMixRequestNameLengthRule: SkillMixRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SkillMixRequest) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SkillMixRequestCeilingRangeRule: SkillMixRequestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SkillMixRequest) -> [String] {
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

    final class SkillMixRequestRequiredNameRule: SkillMixRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SkillMixRequest) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SkillMixRequestCodePrefixRule: SkillMixRequestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SkillMixRequest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SkillMixRequestCodeLengthRule: SkillMixRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SkillMixRequest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a skill mix request.
    final class SkillMixRequestValidator {
        var rules: [any SkillMixRequestRule]

        init(rules: [any SkillMixRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: SkillMixRequest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SkillMixRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SkillMixRequest]) -> [String: [String]] {
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

    static func defaultSkillMixRequestValidator() -> SkillMixRequestValidator {
        return SkillMixRequestValidator(
            rules: [
                SkillMixRequestAllowedCategoryRule(allowed: ["seasonal", "tiered"]),
                SkillMixRequestNameLengthRule(maxLength: 16),
                SkillMixRequestCeilingRangeRule(min: 4.8, max: 776.4),
                SkillMixRequestRequiredNameRule(message: "skill mix request needs this field"),
                SkillMixRequestCodePrefixRule(prefix: "Q"),
                SkillMixRequestCodeLengthRule(maxLength: 255),
            ]
        )
    }
}
