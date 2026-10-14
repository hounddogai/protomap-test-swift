import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a lenient read summary must pass. Check returns its problems, or none.
    protocol LenientReadSummaryRule {
        func check(_ item: LenientReadSummary) -> [String]
    }

    final class LenientReadSummaryRequiredDescriptionRule: LenientReadSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientReadSummary) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientReadSummaryWindowDaysRangeRule: LenientReadSummaryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientReadSummary) -> [String] {
            let value = item.windowDays
            var problems: [String] = []
            if value < min {
                problems.append("window days \(value) is below \(min)")
            }
            if value > max {
                problems.append("window days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LenientReadSummaryRequiredLabelRule: LenientReadSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientReadSummary) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientReadSummaryTagsLimitRule: LenientReadSummaryRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: LenientReadSummary) -> [String] {
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

    /// Runs every rule of a lenient read summary.
    final class LenientReadSummaryValidator {
        var rules: [any LenientReadSummaryRule]

        init(rules: [any LenientReadSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientReadSummary) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientReadSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientReadSummary]) -> [String: [String]] {
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

    static func defaultLenientReadSummaryValidator() -> LenientReadSummaryValidator {
        return LenientReadSummaryValidator(
            rules: [
                LenientReadSummaryRequiredDescriptionRule(message: "lenient read summary needs this field"),
                LenientReadSummaryWindowDaysRangeRule(min: 16, max: 3600),
                LenientReadSummaryRequiredLabelRule(message: "lenient read summary needs an entry"),
                LenientReadSummaryTagsLimitRule(maxCount: 255, banned: ["capped", "batched"]),
            ]
        )
    }
}
