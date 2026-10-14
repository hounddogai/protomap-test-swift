import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a care protocol metric must pass. Check returns its problems, or none.
    protocol CareProtocolMetricRule {
        func check(_ item: CareProtocolMetric) -> [String]
    }

    final class CareProtocolMetricCodePrefixRule: CareProtocolMetricRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CareProtocolMetric) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CareProtocolMetricPriorityRangeRule: CareProtocolMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolMetric) -> [String] {
            let value = item.priority
            var problems: [String] = []
            if value < min {
                problems.append("priority \(value) is below \(min)")
            }
            if value > max {
                problems.append("priority \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CareProtocolMetricRequiredCodeRule: CareProtocolMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolMetric) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolMetricAllowedDescriptionRule: CareProtocolMetricRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CareProtocolMetric) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.description)) {
                return ["description \(item.description) is unknown"]
            }
            return []
        }
    }

    /// Runs every rule of a care protocol metric.
    final class CareProtocolMetricValidator {
        var rules: [any CareProtocolMetricRule]

        init(rules: [any CareProtocolMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolMetric) -> [String] {
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

        func requireValid(_ item: CareProtocolMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolMetric]) -> [String: [String]] {
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

    static func defaultCareProtocolMetricValidator() -> CareProtocolMetricValidator {
        return CareProtocolMetricValidator(
            rules: [
                CareProtocolMetricCodePrefixRule(prefix: "ACM"),
                CareProtocolMetricPriorityRangeRule(min: 32, max: 86400),
                CareProtocolMetricRequiredCodeRule(message: "care protocol metric needs this field"),
                CareProtocolMetricAllowedDescriptionRule(allowed: ["primary"]),
            ]
        )
    }
}
