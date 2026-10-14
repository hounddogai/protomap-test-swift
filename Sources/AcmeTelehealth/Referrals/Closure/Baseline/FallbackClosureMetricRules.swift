import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a fallback closure metric must pass. Check returns its problems, or none.
    protocol FallbackClosureMetricRule {
        func check(_ item: FallbackClosureMetric) -> [String]
    }

    final class FallbackClosureMetricRequiredPayerRule: FallbackClosureMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackClosureMetric) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackClosureMetricCodePrefixRule: FallbackClosureMetricRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackClosureMetric) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackClosureMetricVisibleGuardRule: FallbackClosureMetricRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: FallbackClosureMetric) -> [String] {
            if item.visible && (item.minimum > limit) {
                return ["minimum \(item.minimum) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class FallbackClosureMetricRequiredSegmentRule: FallbackClosureMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackClosureMetric) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackClosureMetricSegmentLengthRule: FallbackClosureMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackClosureMetric) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackClosureMetricRequiredCodeRule: FallbackClosureMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackClosureMetric) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback closure metric.
    final class FallbackClosureMetricValidator {
        var rules: [any FallbackClosureMetricRule]

        init(rules: [any FallbackClosureMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackClosureMetric) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackClosureMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackClosureMetric]) -> [String: [String]] {
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

    static func defaultFallbackClosureMetricValidator() -> FallbackClosureMetricValidator {
        return FallbackClosureMetricValidator(
            rules: [
                FallbackClosureMetricRequiredPayerRule(message: "fallback closure metric needs a value"),
                FallbackClosureMetricCodePrefixRule(prefix: "REF"),
                FallbackClosureMetricVisibleGuardRule(limit: 9.3),
                FallbackClosureMetricRequiredSegmentRule(message: "fallback closure metric needs this field"),
                FallbackClosureMetricSegmentLengthRule(maxLength: 64),
                FallbackClosureMetricRequiredCodeRule(message: "fallback closure metric needs a value"),
            ]
        )
    }
}
