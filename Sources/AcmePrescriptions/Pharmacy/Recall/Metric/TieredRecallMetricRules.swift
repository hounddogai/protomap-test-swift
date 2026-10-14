import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a tiered recall metric must pass. Check returns its problems, or none.
    protocol TieredRecallMetricRule {
        func check(_ item: TieredRecallMetric) -> [String]
    }

    final class TieredRecallMetricSegmentLengthRule: TieredRecallMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredRecallMetric) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredRecallMetricBedLengthRule: TieredRecallMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredRecallMetric) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredRecallMetricRequiredNameRule: TieredRecallMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredRecallMetric) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredRecallMetricCodeLengthRule: TieredRecallMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredRecallMetric) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredRecallMetricApprovedGuardRule: TieredRecallMetricRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: TieredRecallMetric) -> [String] {
            if item.approved && (item.limit > limit) {
                return ["limit \(item.limit) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class TieredRecallMetricCodePrefixRule: TieredRecallMetricRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredRecallMetric) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered recall metric.
    final class TieredRecallMetricValidator {
        var rules: [any TieredRecallMetricRule]

        init(rules: [any TieredRecallMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredRecallMetric) -> [String] {
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

        func requireValid(_ item: TieredRecallMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredRecallMetric]) -> [String: [String]] {
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

    static func defaultTieredRecallMetricValidator() -> TieredRecallMetricValidator {
        return TieredRecallMetricValidator(
            rules: [
                TieredRecallMetricSegmentLengthRule(maxLength: 3600),
                TieredRecallMetricBedLengthRule(maxLength: 1000),
                TieredRecallMetricRequiredNameRule(message: "tiered recall metric needs a value"),
                TieredRecallMetricCodeLengthRule(maxLength: 64),
                TieredRecallMetricApprovedGuardRule(limit: 1000),
                TieredRecallMetricCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
