import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a formulary milestone must pass. Check returns its problems, or none.
    protocol FormularyMilestoneRule {
        func check(_ item: FormularyMilestone) -> [String]
    }

    final class FormularyMilestoneRequiredCodeRule: FormularyMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FormularyMilestone) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FormularyMilestoneCodePrefixRule: FormularyMilestoneRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FormularyMilestone) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FormularyMilestoneVisitMinutesRangeRule: FormularyMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FormularyMilestone) -> [String] {
            let value = item.visitMinutes
            var problems: [String] = []
            if value < min {
                problems.append("visit minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("visit minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FormularyMilestoneTagsLimitRule: FormularyMilestoneRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: FormularyMilestone) -> [String] {
            var problems: [String] = []
            if item.tags.count > maxCount {
                problems.append("has \(item.tags.count) tags, at most \(maxCount) allowed")
            }
            for tag in item.tags {
                if banned.contains(tag) {
                    problems.append("tag \(tag) is not allowed")
                }
            }
            return problems
        }
    }

    /// Runs every rule of a formulary milestone.
    final class FormularyMilestoneValidator {
        var rules: [any FormularyMilestoneRule]

        init(rules: [any FormularyMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: FormularyMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FormularyMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FormularyMilestone]) -> [String: [String]] {
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

    static func defaultFormularyMilestoneValidator() -> FormularyMilestoneValidator {
        return FormularyMilestoneValidator(
            rules: [
                FormularyMilestoneRequiredCodeRule(message: "formulary milestone needs an entry"),
                FormularyMilestoneCodePrefixRule(prefix: "X"),
                FormularyMilestoneVisitMinutesRangeRule(min: 32, max: 64),
                FormularyMilestoneTagsLimitRule(maxCount: 80, banned: ["strict", "tiered"]),
            ]
        )
    }
}
