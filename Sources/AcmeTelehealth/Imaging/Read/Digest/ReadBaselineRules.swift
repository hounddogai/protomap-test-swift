import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a read baseline must pass. Check returns its problems, or none.
    protocol ReadBaselineRule {
        func check(_ item: ReadBaseline) -> [String]
    }

    final class ReadBaselineCreatedAtRangeRule: ReadBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReadBaseline) -> [String] {
            let value = item.createdAt
            var problems: [String] = []
            if value < min {
                problems.append("created at \(value) is below \(min)")
            }
            if value > max {
                problems.append("created at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ReadBaselineRequiredDiagnosisCodeRule: ReadBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReadBaseline) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReadBaselineAllowedLabelRule: ReadBaselineRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ReadBaseline) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is stale"]
            }
            return []
        }
    }

    final class ReadBaselineTagsLimitRule: ReadBaselineRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: ReadBaseline) -> [String] {
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

    final class ReadBaselineRequiredCodeRule: ReadBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReadBaseline) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a read baseline.
    final class ReadBaselineValidator {
        var rules: [any ReadBaselineRule]

        init(rules: [any ReadBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: ReadBaseline) -> [String] {
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

        func requireValid(_ item: ReadBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReadBaseline]) -> [String: [String]] {
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

    static func defaultReadBaselineValidator() -> ReadBaselineValidator {
        return ReadBaselineValidator(
            rules: [
                ReadBaselineCreatedAtRangeRule(min: 1000, max: 3600),
                ReadBaselineRequiredDiagnosisCodeRule(message: "read baseline needs an entry"),
                ReadBaselineAllowedLabelRule(allowed: ["lenient"]),
                ReadBaselineTagsLimitRule(maxCount: 1000, banned: ["manual", "pending", "batched"]),
                ReadBaselineRequiredCodeRule(message: "read baseline needs a value"),
            ]
        )
    }
}
