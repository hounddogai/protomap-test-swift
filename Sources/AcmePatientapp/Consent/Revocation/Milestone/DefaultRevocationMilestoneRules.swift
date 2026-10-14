import AcmePlatform
import Foundation

extension Consent {
    /// A rule a default revocation milestone must pass. Check returns its problems, or none.
    protocol DefaultRevocationMilestoneRule {
        func check(_ item: DefaultRevocationMilestone) -> [String]
    }

    final class DefaultRevocationMilestoneCodeLengthRule: DefaultRevocationMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultRevocationMilestone) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultRevocationMilestoneLimitRangeRule: DefaultRevocationMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultRevocationMilestone) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DefaultRevocationMilestoneRatioRangeRule: DefaultRevocationMilestoneRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultRevocationMilestone) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultRevocationMilestoneRequiredTitleRule: DefaultRevocationMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultRevocationMilestone) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultRevocationMilestoneAllergyLengthRule: DefaultRevocationMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultRevocationMilestone) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a default revocation milestone.
    final class DefaultRevocationMilestoneValidator {
        var rules: [any DefaultRevocationMilestoneRule]

        init(rules: [any DefaultRevocationMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultRevocationMilestone) -> [String] {
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

        func requireValid(_ item: DefaultRevocationMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultRevocationMilestone]) -> [String: [String]] {
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

    static func defaultDefaultRevocationMilestoneValidator() -> DefaultRevocationMilestoneValidator {
        return DefaultRevocationMilestoneValidator(
            rules: [
                DefaultRevocationMilestoneCodeLengthRule(maxLength: 32),
                DefaultRevocationMilestoneLimitRangeRule(min: 16, max: 86400),
                DefaultRevocationMilestoneRatioRangeRule(min: 3.6, max: 2757.6),
                DefaultRevocationMilestoneRequiredTitleRule(message: "default revocation milestone needs a value"),
                DefaultRevocationMilestoneAllergyLengthRule(maxLength: 86400),
            ]
        )
    }
}
