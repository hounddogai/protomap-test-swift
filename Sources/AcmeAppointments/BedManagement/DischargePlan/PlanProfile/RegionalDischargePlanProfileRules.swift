import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a regional discharge plan profile must pass. Check returns its problems, or none.
    protocol RegionalDischargePlanProfileRule {
        func check(_ item: RegionalDischargePlanProfile) -> [String]
    }

    final class RegionalDischargePlanProfileRatioRangeRule: RegionalDischargePlanProfileRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalDischargePlanProfile) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalDischargePlanProfileRequiredCodeRule: RegionalDischargePlanProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalDischargePlanProfile) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalDischargePlanProfileTagsLimitRule: RegionalDischargePlanProfileRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: RegionalDischargePlanProfile) -> [String] {
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

    final class RegionalDischargePlanProfileRequiredRegionRule: RegionalDischargePlanProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalDischargePlanProfile) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional discharge plan profile.
    final class RegionalDischargePlanProfileValidator {
        var rules: [any RegionalDischargePlanProfileRule]

        init(rules: [any RegionalDischargePlanProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalDischargePlanProfile) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalDischargePlanProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalDischargePlanProfile]) -> [String: [String]] {
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

    static func defaultRegionalDischargePlanProfileValidator() -> RegionalDischargePlanProfileValidator {
        return RegionalDischargePlanProfileValidator(
            rules: [
                RegionalDischargePlanProfileRatioRangeRule(min: 1.1, max: 1870.8),
                RegionalDischargePlanProfileRequiredCodeRule(message: "regional discharge plan profile needs a value"),
                RegionalDischargePlanProfileTagsLimitRule(maxCount: 86400, banned: ["global", "weighted"]),
                RegionalDischargePlanProfileRequiredRegionRule(
                    message: "regional discharge plan profile needs this field"
                ),
            ]
        )
    }
}
