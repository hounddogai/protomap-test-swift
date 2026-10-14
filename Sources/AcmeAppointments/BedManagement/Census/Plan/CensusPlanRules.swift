import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a census plan must pass. Check returns its problems, or none.
    protocol CensusPlanRule {
        func check(_ item: CensusPlan) -> [String]
    }

    final class CensusPlanMinimumRangeRule: CensusPlanRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CensusPlan) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CensusPlanTitleLengthRule: CensusPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusPlan) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CensusPlanTagsLimitRule: CensusPlanRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: CensusPlan) -> [String] {
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

    final class CensusPlanRequiredCodeRule: CensusPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CensusPlan) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CensusPlanDurationMinutesRangeRule: CensusPlanRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CensusPlan) -> [String] {
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

    final class CensusPlanCodeLengthRule: CensusPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusPlan) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a census plan.
    final class CensusPlanValidator {
        var rules: [any CensusPlanRule]

        init(rules: [any CensusPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: CensusPlan) -> [String] {
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

        func requireValid(_ item: CensusPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CensusPlan]) -> [String: [String]] {
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

    static func defaultCensusPlanValidator() -> CensusPlanValidator {
        return CensusPlanValidator(
            rules: [
                CensusPlanMinimumRangeRule(min: 4.5, max: 4158.5),
                CensusPlanTitleLengthRule(maxLength: 120),
                CensusPlanTagsLimitRule(maxCount: 16, banned: ["fallback", "strict", "seasonal"]),
                CensusPlanRequiredCodeRule(message: "census plan needs an entry"),
                CensusPlanDurationMinutesRangeRule(min: 16, max: 255),
                CensusPlanCodeLengthRule(maxLength: 80),
            ]
        )
    }
}
