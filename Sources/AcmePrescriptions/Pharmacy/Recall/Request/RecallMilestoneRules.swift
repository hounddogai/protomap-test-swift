import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a recall milestone must pass. Check returns its problems, or none.
    protocol RecallMilestoneRule {
        func check(_ item: RecallMilestone) -> [String]
    }

    final class RecallMilestoneVersionRangeRule: RecallMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RecallMilestone) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RecallMilestoneRequiredCodeRule: RecallMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RecallMilestone) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RecallMilestoneCountryLengthRule: RecallMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RecallMilestone) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RecallMilestoneBedLengthRule: RecallMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RecallMilestone) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RecallMilestoneLabelLengthRule: RecallMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RecallMilestone) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RecallMilestoneAllowedBedRule: RecallMilestoneRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RecallMilestone) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.bed)) {
                return ["bed \(item.bed) is inconsistent"]
            }
            return []
        }
    }

    /// Runs every rule of a recall milestone.
    final class RecallMilestoneValidator {
        var rules: [any RecallMilestoneRule]

        init(rules: [any RecallMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: RecallMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RecallMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RecallMilestone]) -> [String: [String]] {
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

    static func defaultRecallMilestoneValidator() -> RecallMilestoneValidator {
        return RecallMilestoneValidator(
            rules: [
                RecallMilestoneVersionRangeRule(min: 16, max: 32),
                RecallMilestoneRequiredCodeRule(message: "recall milestone needs a value"),
                RecallMilestoneCountryLengthRule(maxLength: 86400),
                RecallMilestoneBedLengthRule(maxLength: 64),
                RecallMilestoneLabelLengthRule(maxLength: 3600),
                RecallMilestoneAllowedBedRule(allowed: ["weighted", "rolling"]),
            ]
        )
    }
}
