import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a order set metric must pass. Check returns its problems, or none.
    protocol OrderSetMetricRule {
        func check(_ item: OrderSetMetric) -> [String]
    }

    final class OrderSetMetricPinnedGuardRule: OrderSetMetricRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: OrderSetMetric) -> [String] {
            if item.pinned && (item.windowDays > limit) {
                return ["window days \(item.windowDays) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class OrderSetMetricCodeLengthRule: OrderSetMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OrderSetMetric) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OrderSetMetricAllowedSourceRule: OrderSetMetricRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: OrderSetMetric) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.source)) {
                return ["source \(item.source) is expired"]
            }
            return []
        }
    }

    final class OrderSetMetricTagsLimitRule: OrderSetMetricRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: OrderSetMetric) -> [String] {
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

    final class OrderSetMetricRequiredTitleRule: OrderSetMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OrderSetMetric) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a order set metric.
    final class OrderSetMetricValidator {
        var rules: [any OrderSetMetricRule]

        init(rules: [any OrderSetMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: OrderSetMetric) -> [String] {
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

        func requireValid(_ item: OrderSetMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OrderSetMetric]) -> [String: [String]] {
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

    static func defaultOrderSetMetricValidator() -> OrderSetMetricValidator {
        return OrderSetMetricValidator(
            rules: [
                OrderSetMetricPinnedGuardRule(limit: 32),
                OrderSetMetricCodeLengthRule(maxLength: 64),
                OrderSetMetricAllowedSourceRule(allowed: ["fallback"]),
                OrderSetMetricTagsLimitRule(maxCount: 120, banned: ["scheduled"]),
                OrderSetMetricRequiredTitleRule(message: "order set metric needs an entry"),
            ]
        )
    }
}
