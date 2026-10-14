import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a regional dispense estimate must pass. Check returns its problems, or none.
    protocol RegionalDispenseEstimateRule {
        func check(_ item: RegionalDispenseEstimate) -> [String]
    }

    final class RegionalDispenseEstimateTagsLimitRule: RegionalDispenseEstimateRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: RegionalDispenseEstimate) -> [String] {
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

    final class RegionalDispenseEstimateRequiredUnitRule: RegionalDispenseEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalDispenseEstimate) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalDispenseEstimateRequiredNameRule: RegionalDispenseEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalDispenseEstimate) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalDispenseEstimateUnitLengthRule: RegionalDispenseEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalDispenseEstimate) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalDispenseEstimateExpiresAtRangeRule: RegionalDispenseEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalDispenseEstimate) -> [String] {
            let value = item.expiresAt
            var problems: [String] = []
            if value < min {
                problems.append("expires at \(value) is below \(min)")
            }
            if value > max {
                problems.append("expires at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a regional dispense estimate.
    final class RegionalDispenseEstimateValidator {
        var rules: [any RegionalDispenseEstimateRule]

        init(rules: [any RegionalDispenseEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalDispenseEstimate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalDispenseEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalDispenseEstimate]) -> [String: [String]] {
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

    static func defaultRegionalDispenseEstimateValidator() -> RegionalDispenseEstimateValidator {
        return RegionalDispenseEstimateValidator(
            rules: [
                RegionalDispenseEstimateTagsLimitRule(maxCount: 255, banned: ["adaptive"]),
                RegionalDispenseEstimateRequiredUnitRule(message: "regional dispense estimate needs a value"),
                RegionalDispenseEstimateRequiredNameRule(message: "regional dispense estimate needs this field"),
                RegionalDispenseEstimateUnitLengthRule(maxLength: 16),
                RegionalDispenseEstimateExpiresAtRangeRule(min: 1000, max: 3600),
            ]
        )
    }
}
