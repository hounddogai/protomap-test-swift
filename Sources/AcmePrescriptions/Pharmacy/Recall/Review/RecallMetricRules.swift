import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a recall metric must pass. Check returns its problems, or none.
    protocol RecallMetricRule {
        func check(_ item: RecallMetric) -> [String]
    }

    final class RecallMetricAllowedSpecialtyRule: RecallMetricRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RecallMetric) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.specialty)) {
                return ["specialty \(item.specialty) is missing"]
            }
            return []
        }
    }

    final class RecallMetricVisibleGuardRule: RecallMetricRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: RecallMetric) -> [String] {
            if item.visible && (item.limit > limit) {
                return ["limit \(item.limit) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class RecallMetricRequiredSourceRule: RecallMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RecallMetric) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a recall metric.
    final class RecallMetricValidator {
        var rules: [any RecallMetricRule]

        init(rules: [any RecallMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: RecallMetric) -> [String] {
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

        func requireValid(_ item: RecallMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RecallMetric]) -> [String: [String]] {
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

    static func defaultRecallMetricValidator() -> RecallMetricValidator {
        return RecallMetricValidator(
            rules: [
                RecallMetricAllowedSpecialtyRule(allowed: []),
                RecallMetricVisibleGuardRule(limit: 255),
                RecallMetricRequiredSourceRule(message: "recall metric needs this field"),
            ]
        )
    }
}
