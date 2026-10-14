import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a float pool baseline must pass. Check returns its problems, or none.
    protocol FloatPoolBaselineRule {
        func check(_ item: FloatPoolBaseline) -> [String]
    }

    final class FloatPoolBaselineRequiredPatientRefRule: FloatPoolBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FloatPoolBaseline) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FloatPoolBaselineAllowedCodeRule: FloatPoolBaselineRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FloatPoolBaseline) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is inconsistent"]
            }
            return []
        }
    }

    final class FloatPoolBaselineStartsAtRangeRule: FloatPoolBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FloatPoolBaseline) -> [String] {
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

    final class FloatPoolBaselineCodeLengthRule: FloatPoolBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FloatPoolBaseline) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FloatPoolBaselineRequiredSegmentRule: FloatPoolBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FloatPoolBaseline) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FloatPoolBaselineTagsLimitRule: FloatPoolBaselineRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: FloatPoolBaseline) -> [String] {
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

    /// Runs every rule of a float pool baseline.
    final class FloatPoolBaselineValidator {
        var rules: [any FloatPoolBaselineRule]

        init(rules: [any FloatPoolBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: FloatPoolBaseline) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FloatPoolBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FloatPoolBaseline]) -> [String: [String]] {
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

    static func defaultFloatPoolBaselineValidator() -> FloatPoolBaselineValidator {
        return FloatPoolBaselineValidator(
            rules: [
                FloatPoolBaselineRequiredPatientRefRule(message: "float pool baseline needs an entry"),
                FloatPoolBaselineAllowedCodeRule(allowed: ["fallback", "capped"]),
                FloatPoolBaselineStartsAtRangeRule(min: 120, max: 86400),
                FloatPoolBaselineCodeLengthRule(maxLength: 64),
                FloatPoolBaselineRequiredSegmentRule(message: "float pool baseline needs an entry"),
                FloatPoolBaselineTagsLimitRule(maxCount: 1000, banned: ["default"]),
            ]
        )
    }
}
