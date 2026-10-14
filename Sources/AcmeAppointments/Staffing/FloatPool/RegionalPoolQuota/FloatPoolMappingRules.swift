import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a float pool mapping must pass. Check returns its problems, or none.
    protocol FloatPoolMappingRule {
        func check(_ item: FloatPoolMapping) -> [String]
    }

    final class FloatPoolMappingTagsLimitRule: FloatPoolMappingRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: FloatPoolMapping) -> [String] {
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

    final class FloatPoolMappingTitleLengthRule: FloatPoolMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FloatPoolMapping) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FloatPoolMappingRetriesRangeRule: FloatPoolMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FloatPoolMapping) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FloatPoolMappingCodePrefixRule: FloatPoolMappingRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FloatPoolMapping) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a float pool mapping.
    final class FloatPoolMappingValidator {
        var rules: [any FloatPoolMappingRule]

        init(rules: [any FloatPoolMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: FloatPoolMapping) -> [String] {
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

        func requireValid(_ item: FloatPoolMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FloatPoolMapping]) -> [String: [String]] {
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

    static func defaultFloatPoolMappingValidator() -> FloatPoolMappingValidator {
        return FloatPoolMappingValidator(
            rules: [
                FloatPoolMappingTagsLimitRule(maxCount: 1000, banned: ["default"]),
                FloatPoolMappingTitleLengthRule(maxLength: 64),
                FloatPoolMappingRetriesRangeRule(min: 120, max: 255),
                FloatPoolMappingCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
