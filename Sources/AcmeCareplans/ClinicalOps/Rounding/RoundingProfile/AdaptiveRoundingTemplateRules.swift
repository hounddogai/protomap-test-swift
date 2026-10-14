import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a adaptive rounding template must pass. Check returns its problems, or none.
    protocol AdaptiveRoundingTemplateRule {
        func check(_ item: AdaptiveRoundingTemplate) -> [String]
    }

    final class AdaptiveRoundingTemplateTagsLimitRule: AdaptiveRoundingTemplateRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: AdaptiveRoundingTemplate) -> [String] {
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

    final class AdaptiveRoundingTemplateNameLengthRule: AdaptiveRoundingTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveRoundingTemplate) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveRoundingTemplateStartsAtRangeRule: AdaptiveRoundingTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveRoundingTemplate) -> [String] {
            let value = item.startsAt
            var problems: [String] = []
            if value < min {
                problems.append("starts at \(value) is below \(min)")
            }
            if value > max {
                problems.append("starts at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AdaptiveRoundingTemplateCodePrefixRule: AdaptiveRoundingTemplateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveRoundingTemplate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveRoundingTemplateApprovedGuardRule: AdaptiveRoundingTemplateRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: AdaptiveRoundingTemplate) -> [String] {
            if item.approved && (item.acuity > limit) {
                return ["acuity \(item.acuity) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class AdaptiveRoundingTemplateDurationMinutesRangeRule: AdaptiveRoundingTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveRoundingTemplate) -> [String] {
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

    /// Runs every rule of a adaptive rounding template.
    final class AdaptiveRoundingTemplateValidator {
        var rules: [any AdaptiveRoundingTemplateRule]

        init(rules: [any AdaptiveRoundingTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveRoundingTemplate) -> [String] {
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

        func requireValid(_ item: AdaptiveRoundingTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveRoundingTemplate]) -> [String: [String]] {
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

    static func defaultAdaptiveRoundingTemplateValidator() -> AdaptiveRoundingTemplateValidator {
        return AdaptiveRoundingTemplateValidator(
            rules: [
                AdaptiveRoundingTemplateTagsLimitRule(maxCount: 32, banned: ["tiered"]),
                AdaptiveRoundingTemplateNameLengthRule(maxLength: 86400),
                AdaptiveRoundingTemplateStartsAtRangeRule(min: 16, max: 255),
                AdaptiveRoundingTemplateCodePrefixRule(prefix: "REF"),
                AdaptiveRoundingTemplateApprovedGuardRule(limit: 120),
                AdaptiveRoundingTemplateDurationMinutesRangeRule(min: 120, max: 3600),
            ]
        )
    }
}
