import AcmePlatform
import Foundation

extension Labs {
    /// A rule a global courier mapping must pass. Check returns its problems, or none.
    protocol GlobalCourierMappingRule {
        func check(_ item: GlobalCourierMapping) -> [String]
    }

    final class GlobalCourierMappingDosageMgRangeRule: GlobalCourierMappingRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalCourierMapping) -> [String] {
            let value = item.dosageMg
            var problems: [String] = []
            if value < min {
                problems.append("dosage mg \(value) is below \(min)")
            }
            if value > max {
                problems.append("dosage mg \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GlobalCourierMappingActiveGuardRule: GlobalCourierMappingRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: GlobalCourierMapping) -> [String] {
            if item.active && (item.expiresAt > limit) {
                return ["expires at \(item.expiresAt) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class GlobalCourierMappingTagsLimitRule: GlobalCourierMappingRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: GlobalCourierMapping) -> [String] {
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

    /// Runs every rule of a global courier mapping.
    final class GlobalCourierMappingValidator {
        var rules: [any GlobalCourierMappingRule]

        init(rules: [any GlobalCourierMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalCourierMapping) -> [String] {
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

        func requireValid(_ item: GlobalCourierMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalCourierMapping]) -> [String: [String]] {
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

    static func defaultGlobalCourierMappingValidator() -> GlobalCourierMappingValidator {
        return GlobalCourierMappingValidator(
            rules: [
                GlobalCourierMappingDosageMgRangeRule(min: 1.5, max: 1992.6),
                GlobalCourierMappingActiveGuardRule(limit: 80),
                GlobalCourierMappingTagsLimitRule(maxCount: 64, banned: ["fallback", "manual"]),
            ]
        )
    }
}
