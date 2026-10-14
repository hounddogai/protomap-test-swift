import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a discharge plan mapping must pass. Check returns its problems, or none.
    protocol DischargePlanMappingRule {
        func check(_ item: DischargePlanMapping) -> [String]
    }

    final class DischargePlanMappingDurationMinutesRangeRule: DischargePlanMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DischargePlanMapping) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DischargePlanMappingUpdatedAtRangeRule: DischargePlanMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DischargePlanMapping) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DischargePlanMappingTagsLimitRule: DischargePlanMappingRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: DischargePlanMapping) -> [String] {
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

    final class DischargePlanMappingCodeLengthRule: DischargePlanMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DischargePlanMapping) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DischargePlanMappingDiscountRangeRule: DischargePlanMappingRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DischargePlanMapping) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a discharge plan mapping.
    final class DischargePlanMappingValidator {
        var rules: [any DischargePlanMappingRule]

        init(rules: [any DischargePlanMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: DischargePlanMapping) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DischargePlanMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DischargePlanMapping]) -> [String: [String]] {
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

    static func defaultDischargePlanMappingValidator() -> DischargePlanMappingValidator {
        return DischargePlanMappingValidator(
            rules: [
                DischargePlanMappingDurationMinutesRangeRule(min: 80, max: 255),
                DischargePlanMappingUpdatedAtRangeRule(min: 1000, max: 3600),
                DischargePlanMappingTagsLimitRule(maxCount: 86400, banned: ["rolling", "global"]),
                DischargePlanMappingCodeLengthRule(maxLength: 16),
                DischargePlanMappingDiscountRangeRule(min: 9.7, max: 3412.3),
            ]
        )
    }
}
