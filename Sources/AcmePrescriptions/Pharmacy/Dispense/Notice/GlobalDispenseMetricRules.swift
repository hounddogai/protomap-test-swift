import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a global dispense metric must pass. Check returns its problems, or none.
    protocol GlobalDispenseMetricRule {
        func check(_ item: GlobalDispenseMetric) -> [String]
    }

    final class GlobalDispenseMetricNameLengthRule: GlobalDispenseMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalDispenseMetric) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalDispenseMetricRequiredChecksumRule: GlobalDispenseMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalDispenseMetric) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalDispenseMetricChecksumLengthRule: GlobalDispenseMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalDispenseMetric) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalDispenseMetricGraceDaysRangeRule: GlobalDispenseMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalDispenseMetric) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalDispenseMetricTagsLimitRule: GlobalDispenseMetricRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: GlobalDispenseMetric) -> [String] {
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

    /// Runs every rule of a global dispense metric.
    final class GlobalDispenseMetricValidator {
        var rules: [any GlobalDispenseMetricRule]

        init(rules: [any GlobalDispenseMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalDispenseMetric) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalDispenseMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalDispenseMetric]) -> [String: [String]] {
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

    static func defaultGlobalDispenseMetricValidator() -> GlobalDispenseMetricValidator {
        return GlobalDispenseMetricValidator(
            rules: [
                GlobalDispenseMetricNameLengthRule(maxLength: 120),
                GlobalDispenseMetricRequiredChecksumRule(message: "global dispense metric needs a value"),
                GlobalDispenseMetricChecksumLengthRule(maxLength: 32),
                GlobalDispenseMetricGraceDaysRangeRule(min: 64, max: 64),
                GlobalDispenseMetricTagsLimitRule(maxCount: 64, banned: ["lenient", "weighted", "global"]),
            ]
        )
    }
}
