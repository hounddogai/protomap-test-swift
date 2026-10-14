import AcmePlatform
import Foundation

extension Consent {
    /// A rule a witness notice must pass. Check returns its problems, or none.
    protocol WitnessNoticeRule {
        func check(_ item: WitnessNotice) -> [String]
    }

    final class WitnessNoticeWindowDaysRangeRule: WitnessNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WitnessNotice) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WitnessNoticeDiscountRangeRule: WitnessNoticeRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WitnessNotice) -> [String] {
            let value = item.discount
            var problems: [String] = []
            if value < min {
                problems.append("discount \(value) is below \(min)")
            }
            if value > max {
                problems.append("discount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WitnessNoticeCodeLengthRule: WitnessNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WitnessNotice) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WitnessNoticeScoreRangeRule: WitnessNoticeRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WitnessNotice) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WitnessNoticeTagsLimitRule: WitnessNoticeRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: WitnessNotice) -> [String] {
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

    final class WitnessNoticeNameLengthRule: WitnessNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WitnessNotice) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a witness notice.
    final class WitnessNoticeValidator {
        var rules: [any WitnessNoticeRule]

        init(rules: [any WitnessNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: WitnessNotice) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WitnessNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WitnessNotice]) -> [String: [String]] {
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

    static func defaultWitnessNoticeValidator() -> WitnessNoticeValidator {
        return WitnessNoticeValidator(
            rules: [
                WitnessNoticeWindowDaysRangeRule(min: 64, max: 64),
                WitnessNoticeDiscountRangeRule(min: 7.4, max: 3156.4),
                WitnessNoticeCodeLengthRule(maxLength: 80),
                WitnessNoticeScoreRangeRule(min: 2.9, max: 2286.0),
                WitnessNoticeTagsLimitRule(maxCount: 80, banned: ["scheduled", "scheduled", "primary"]),
                WitnessNoticeNameLengthRule(maxLength: 120),
            ]
        )
    }
}
