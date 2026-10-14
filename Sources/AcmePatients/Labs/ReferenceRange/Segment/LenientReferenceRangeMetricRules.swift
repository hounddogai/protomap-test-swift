import AcmePlatform
import Foundation

extension Labs {
    /// A rule a lenient reference range metric must pass. Check returns its problems, or none.
    protocol LenientReferenceRangeMetricRule {
        func check(_ item: LenientReferenceRangeMetric) -> [String]
    }

    final class LenientReferenceRangeMetricApprovedGuardRule: LenientReferenceRangeMetricRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: LenientReferenceRangeMetric) -> [String] {
            if item.approved && (item.discount > limit) {
                return ["discount \(item.discount) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class LenientReferenceRangeMetricRateRangeRule: LenientReferenceRangeMetricRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientReferenceRangeMetric) -> [String] {
            let value = item.rate
            var problems: [String] = []
            if value < min {
                problems.append("rate \(value) is below \(min)")
            }
            if value > max {
                problems.append("rate \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LenientReferenceRangeMetricAllowedCodeRule: LenientReferenceRangeMetricRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LenientReferenceRangeMetric) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is blocked"]
            }
            return []
        }
    }

    final class LenientReferenceRangeMetricRequiredTitleRule: LenientReferenceRangeMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientReferenceRangeMetric) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientReferenceRangeMetricCodePrefixRule: LenientReferenceRangeMetricRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LenientReferenceRangeMetric) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LenientReferenceRangeMetricTitleLengthRule: LenientReferenceRangeMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientReferenceRangeMetric) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient reference range metric.
    final class LenientReferenceRangeMetricValidator {
        var rules: [any LenientReferenceRangeMetricRule]

        init(rules: [any LenientReferenceRangeMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientReferenceRangeMetric) -> [String] {
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

        func requireValid(_ item: LenientReferenceRangeMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientReferenceRangeMetric]) -> [String: [String]] {
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

    static func defaultLenientReferenceRangeMetricValidator() -> LenientReferenceRangeMetricValidator {
        return LenientReferenceRangeMetricValidator(
            rules: [
                LenientReferenceRangeMetricApprovedGuardRule(limit: 1.0),
                LenientReferenceRangeMetricRateRangeRule(min: 1.2, max: 2787.2),
                LenientReferenceRangeMetricAllowedCodeRule(allowed: ["scheduled", "tiered", "lenient"]),
                LenientReferenceRangeMetricRequiredTitleRule(message: "lenient reference range metric needs an entry"),
                LenientReferenceRangeMetricCodePrefixRule(prefix: "REF"),
                LenientReferenceRangeMetricTitleLengthRule(maxLength: 86400),
            ]
        )
    }
}
